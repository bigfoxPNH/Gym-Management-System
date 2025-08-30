import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/membership_card.dart';
import '../models/membership_purchase.dart';
import '../models/payment_method.dart';
import '../models/payment_transaction.dart';
import '../services/payment_service.dart';
import '../services/membership_purchase_service.dart';
import '../services/momo_payment_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/payment_callback_controller.dart';

class CheckoutController extends GetxController {
  final PaymentService _paymentService = PaymentService();
  final MoMoPaymentService _momoService = MoMoPaymentService();
  final AuthController _authController = Get.find<AuthController>();
  final PaymentCallbackController _callbackController = Get.put(
    PaymentCallbackController(),
  );

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final Rx<PaymentTransaction?> currentTransaction = Rx<PaymentTransaction?>(
    null,
  );
  final RxList<PaymentMethod> availablePaymentMethods = <PaymentMethod>[].obs;
  final Rx<PaymentMethod?> selectedPaymentMethod = Rx<PaymentMethod?>(null);

  // Checkout data
  MembershipCard? membershipCard;
  String? membershipPurchaseId;
  Timer? _paymentCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _loadAvailablePaymentMethods();
  }

  @override
  void onClose() {
    _paymentCheckTimer?.cancel();
    super.onClose();
  }

  // Initialize checkout with membership card
  void initializeCheckout(MembershipCard card, String purchaseId) {
    membershipCard = card;
    membershipPurchaseId = purchaseId;
    currentTransaction.value = null;
    selectedPaymentMethod.value = null;
  }

  // Load available payment methods
  void _loadAvailablePaymentMethods() {
    try {
      final methods = _paymentService.getAvailablePaymentMethods();
      availablePaymentMethods.assignAll(methods);

      // Auto select first available method
      if (methods.isNotEmpty) {
        selectedPaymentMethod.value = methods.first;
      }
    } catch (e) {
      print('Error loading payment methods: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải phương thức thanh toán',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Select payment method
  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod.value = method;
  }

  // Create payment transaction
  Future<bool> createPayment() async {
    if (membershipCard == null ||
        membershipPurchaseId == null ||
        selectedPaymentMethod.value == null) {
      Get.snackbar(
        'Lỗi',
        'Thông tin thanh toán không đầy đủ',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    if (_authController.userAccount == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng đăng nhập để tiếp tục',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isLoading.value = true;
      isProcessingPayment.value = true;

      // Create payment transaction
      final transaction = PaymentTransaction(
        id: 'PAY_\${DateTime.now().millisecondsSinceEpoch}',
        userId: _authController.userAccount!.id,
        membershipCardId: membershipCard!.id,
        membershipPurchaseId: membershipPurchaseId!,
        paymentType: PaymentType.membership,
        paymentMethod: selectedPaymentMethod.value!.type,
        amount: membershipCard!.price,
        status: PaymentStatus.pending,
        description: 'Mua thẻ tập \${membershipCard!.cardName}',
        createdAt: DateTime.now(),
      );

      currentTransaction.value = transaction;

      // Process payment based on selected method
      if (selectedPaymentMethod.value!.type == PaymentMethodType.momo) {
        return await _processMoMoPayment();
      } else {
        // Handle other payment methods
        Get.snackbar(
          'Thông báo',
          'Phương thức thanh toán \${selectedPaymentMethod.value!.displayName} sẽ sớm có sẵn',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      print('Error creating payment: $e');
      Get.snackbar(
        'Lỗi thanh toán',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
      isProcessingPayment.value = false;
    }
  }

  /// Process MoMo payment
  Future<bool> _processMoMoPayment() async {
    try {
      print('🔄 Processing MoMo payment for membership card');

      if (currentTransaction.value == null) {
        throw Exception('No transaction found');
      }

      final transaction = currentTransaction.value!;

      // Create MoMo payment
      final momoResponse = await _momoService.createPayment(
        orderId: transaction.id,
        amount: transaction.amount.toInt(),
        orderInfo: transaction.description ?? 'Mua thẻ tập GymPro',
      );

      if (momoResponse == null || !momoResponse.isSuccess) {
        throw Exception(
          momoResponse?.message ?? 'Tạo thanh toán MoMo thất bại',
        );
      }

      // Show QR code for payment (web-friendly)
      if (kIsWeb || !(await _momoService.launchMoMoPayment(momoResponse))) {
        _showMoMoQRDialog(momoResponse, transaction);
      }

      // Start watching payment status
      _watchPaymentStatus();

      // Navigate to payment status page
      Get.toNamed('/payment/status', arguments: transaction.id);
      return true;
    } catch (e) {
      print('❌ Error processing MoMo payment: $e');
      Get.snackbar(
        'Lỗi thanh toán MoMo',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Show MoMo QR dialog for checkout
  void _showMoMoQRDialog(dynamic momoResponse, PaymentTransaction transaction) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code, color: Colors.purple),
            SizedBox(width: 8),
            Text('Thanh toán MoMo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thông tin đơn hàng
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('${membershipCard?.cardName ?? 'Thẻ tập'}'),
                    Text(
                      'Số tiền: ${getFormattedTotalAmount()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Mã đơn: ${transaction.id}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Hướng dẫn thanh toán
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Hướng dẫn thanh toán:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Mở ứng dụng MoMo trên điện thoại'),
                    Text('2. Chọn "Quét mã QR"'),
                    Text('3. Quét mã QR bên dưới để thanh toán'),
                    Text('4. Xác nhận thanh toán trong ứng dụng MoMo'),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // QR Code placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 60, color: Colors.grey[600]),
                    SizedBox(height: 8),
                    Text(
                      'Mã QR MoMo',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '\${transaction.id}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Thông báo chờ thanh toán
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đang chờ bạn thanh toán...',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Hủy')),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.toNamed('/payment/status', arguments: transaction.id);
            },
            icon: Icon(Icons.payment),
            label: Text('Xem trạng thái'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          // Test button cho development
          if (!kReleaseMode)
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                simulatePaymentSuccess();
              },
              icon: Icon(Icons.check_circle),
              label: Text('Test OK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  // Watch payment status
  void _watchPaymentStatus() {
    _paymentCheckTimer?.cancel();

    if (currentTransaction.value != null) {
      final orderId = currentTransaction.value!.id;

      // Listen to payment status updates
      _callbackController.watchPaymentStatus(orderId).listen((transaction) {
        if (transaction != null) {
          currentTransaction.value = transaction;

          if (transaction.status == PaymentStatus.completed) {
            _handlePaymentSuccess();
          } else if (transaction.status == PaymentStatus.failed) {
            _handlePaymentFailure();
          }
        }
      });

      // Also check periodically
      _paymentCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (currentTransaction.value != null) {
          checkPaymentStatus();

          // Stop checking if payment is completed or failed
          if (currentTransaction.value!.status == PaymentStatus.completed ||
              currentTransaction.value!.status == PaymentStatus.failed) {
            timer.cancel();
          }
        }
      });
    }
  }

  // Check payment status manually
  Future<void> checkPaymentStatus() async {
    if (currentTransaction.value == null) return;

    try {
      // In a real app, this would call a backend service
      print('Checking payment status for \${currentTransaction.value!.id}');
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  // Handle successful payment
  void _handlePaymentSuccess() {
    if (currentTransaction.value == null) return;

    if (currentTransaction.value!.status == PaymentStatus.completed) {
      Get.snackbar(
        'Thanh toán thành công!',
        'Thẻ tập của bạn đã được kích hoạt',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to success page
      Get.offAllNamed('/payment/success');
    } else if (currentTransaction.value!.status == PaymentStatus.failed) {
      _handlePaymentFailure();
    }
  }

  // Handle failed payment
  void _handlePaymentFailure() {
    Get.snackbar(
      'Thanh toán thất bại',
      'Vui lòng thử lại hoặc chọn phương thức khác',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // Simulate payment success (for testing)
  Future<void> simulatePaymentSuccess() async {
    if (currentTransaction.value == null) return;

    isLoading.value = true;

    try {
      // Simulate payment completion
      currentTransaction.value = currentTransaction.value!.copyWith(
        status: PaymentStatus.completed,
      );

      Get.snackbar(
        'Thanh toán thành công!',
        'Thẻ tập của bạn đã được kích hoạt',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error simulating payment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Cancel payment
  Future<void> cancelPayment() async {
    if (currentTransaction.value == null ||
        currentTransaction.value!.status != PaymentStatus.pending) {
      return;
    }

    try {
      isLoading.value = true;

      // Update transaction status
      currentTransaction.value = currentTransaction.value!.copyWith(
        status: PaymentStatus.cancelled,
      );

      _paymentCheckTimer?.cancel();
      currentTransaction.value = null;

      Get.snackbar(
        'Đã hủy thanh toán',
        'Bạn có thể thử lại bất cứ lúc nào',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back();
    } catch (e) {
      print('Error cancelling payment: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Retry payment
  Future<void> retryPayment() async {
    currentTransaction.value = null;
    await createPayment();
  }

  // Get formatted payment method name
  String getPaymentMethodName() {
    return selectedPaymentMethod.value?.displayName ?? '';
  }

  // Get formatted amount
  String getFormattedAmount() {
    if (membershipCard == null) return '';
    return '\${membershipCard!.price.toStringAsFixed(0)} VNĐ';
  }

  // Get transaction fee
  double getTransactionFee() {
    if (selectedPaymentMethod.value?.type == PaymentMethodType.momo) {
      return membershipCard?.price != null ? membershipCard!.price * 0.01 : 0;
    }
    return 0;
  }

  // Get total amount including fees
  double getTotalAmount() {
    final baseAmount = membershipCard?.price ?? 0;
    final fee = getTransactionFee();
    return baseAmount + fee;
  }

  // Get formatted total amount
  String getFormattedTotalAmount() {
    return '\${getTotalAmount().toStringAsFixed(0)} VNĐ';
  }
}
