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

class CheckoutController extends GetxController {
  final PaymentService _paymentService = PaymentService();
  final MoMoPaymentService _momoService = MoMoPaymentService();
  final AuthController _authController = Get.find<AuthController>();

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
        id: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
        userId: _authController.userAccount?.id ?? '',
        membershipCardId: membershipCard!.id,
        membershipPurchaseId: membershipPurchaseId!,
        paymentType: PaymentType.membership,
        paymentMethod: selectedPaymentMethod.value!.type,
        amount: membershipCard!.price,
        status: PaymentStatus.pending,
        description: 'Mua thẻ tập ${membershipCard!.cardName}',
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
          'Phương thức thanh toán ${selectedPaymentMethod.value!.displayName} sẽ sớm có sẵn',
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

  // Check payment status from server
  Future<void> checkPaymentStatus() async {
    if (currentTransaction.value == null) return;

    try {
      final updatedTransaction = await _paymentService.getPaymentTransaction(
        currentTransaction.value!.id,
      );

      if (updatedTransaction != null) {
        currentTransaction.value = updatedTransaction;
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  // Handle payment result
  Future<void> _handlePaymentResult() async {
    if (currentTransaction.value == null) return;

    if (currentTransaction.value!.isCompleted) {
      // Update membership purchase status
      await MembershipPurchaseService.updatePurchaseStatus(
        membershipPurchaseId!,
        PurchaseStatus.active,
      );

      Get.snackbar(
        'Thành công',
        'Thanh toán thành công! Thẻ tập của bạn đã được kích hoạt.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 4),
      );

      // Navigate to success page or membership list
      Get.offAllNamed('/membership-purchase');
    } else if (currentTransaction.value!.isFailed) {
      Get.snackbar(
        'Thất bại',
        'Thanh toán thất bại. Vui lòng thử lại.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  // Simulate payment completion (for demo)
  Future<void> simulatePaymentSuccess() async {
    if (currentTransaction.value == null) return;

    isLoading.value = true;

    try {
      await _paymentService.simulatePaymentCompletion(
        currentTransaction.value!.id,
      );

      await checkPaymentStatus();
      await _handlePaymentResult();
    } catch (e) {
      print('Error simulating payment: $e');
      Get.snackbar(
        'Lỗi',
        'Lỗi xử lý thanh toán: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Cancel payment
  Future<void> cancelPayment() async {
    if (currentTransaction.value == null ||
        !currentTransaction.value!.canCancel) {
      return;
    }

    try {
      isLoading.value = true;

      await _paymentService.updatePaymentStatus(
        currentTransaction.value!.id,
        PaymentStatus.cancelled,
      );

      _paymentCheckTimer?.cancel();
      currentTransaction.value = null;

      Get.back(); // Return to previous screen
    } catch (e) {
      print('Error canceling payment: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể hủy thanh toán: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Retry payment with same or different method
  Future<void> retryPayment() async {
    currentTransaction.value = null;
    await createPayment();
  }

  // Get payment method display info
  String getSelectedMethodDisplayName() {
    return selectedPaymentMethod.value?.displayName ?? '';
  }

  // Get transaction amount formatted
  String getFormattedAmount() {
    if (membershipCard == null) return '';
    return '${membershipCard!.price.toStringAsFixed(0)} VNĐ';
  }

  // Get transaction fee (if any)
  double getTransactionFee() {
    if (selectedPaymentMethod.value?.type == PaymentMethodType.momo) {
      return membershipCard?.price != null
          ? membershipCard!.price * 0.01
          : 0; // 1% fee for MoMo
    }
    return 0; // No fee for other methods
  }

  // Get total amount including fees
  double getTotalAmount() {
    final baseAmount = membershipCard?.price ?? 0;
    final fee = getTransactionFee();
    return baseAmount + fee;
  }

  String getFormattedTotalAmount() {
    return '${getTotalAmount().toStringAsFixed(0)} VNĐ';
  }

  /// Process MoMo payment
  Future<bool> _processMoMoPayment() async {
    try {
      print('🔄 Processing MoMo payment for membership card');

      // Create payment transaction
      final transaction = PaymentTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _authController.userAccount?.id ?? '',
        membershipCardId: membershipCard?.id ?? '',
        membershipPurchaseId: '',
        paymentType: PaymentType.membership,
        paymentMethod: PaymentMethodType.momo,
        amount: getTotalAmount(),
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        description:
            'Mua thẻ tập: ${membershipCard?.cardName ?? 'Không xác định'}',
      );

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
        title: Text('Thanh toán thẻ tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quét mã QR để thanh toán:'),
            Text('${membershipCard?.cardName}'),
            Text('Số tiền: ${getFormattedTotalAmount()}'),
            SizedBox(height: 16),
            // QR Code would be displayed here
            Container(
              width: 200,
              height: 200,
              color: Colors.grey[200],
              child: Center(child: Text('QR Code\n${transaction.id}')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/payment/status', arguments: transaction.id);
            },
            child: Text('Xem trạng thái'),
          ),
        ],
      ),
    );
  }
}
