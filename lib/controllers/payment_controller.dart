import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/momo_payment_service.dart';
import '../models/momo_models.dart';
import '../models/payment_transaction.dart';
import '../models/payment_method.dart';

class PaymentController extends GetxController {
  final MoMoPaymentService _momoService = MoMoPaymentService();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isProcessingPayment = false.obs;
  final RxBool isProcessing = false.obs; // Alias for UI compatibility
  final Rx<PaymentTransaction?> currentTransaction = Rx<PaymentTransaction?>(
    null,
  );
  final RxString paymentStatus = ''.obs;
  final RxString paymentMessage = ''.obs;
  final RxString currentOrderId = ''.obs;
  final RxString currentTransactionId = ''.obs;

  // Form fields for test UI
  final RxInt paymentAmount = 10000.obs;
  final RxString orderInfo = 'Test payment GymPro'.obs;

  // Callback subscription
  StreamSubscription<MoMoCallbackResult>? _callbackSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializePaymentService();

    // Sync isProcessing with isProcessingPayment
    ever(isProcessingPayment, (value) {
      isProcessing.value = value;
    });
  }

  @override
  void onClose() {
    _callbackSubscription?.cancel();
    _momoService.dispose();
    super.onClose();
  }

  Future<void> _initializePaymentService() async {
    try {
      await _momoService.initialize();

      // Listen for payment callbacks
      _callbackSubscription = _momoService.callbackStream.listen(
        (MoMoCallbackResult result) {
          _handlePaymentCallback(result);
        },
        onError: (error) {
          print('❌ Payment callback error: $error');
        },
      );

      print('✅ PaymentController initialized');
    } catch (e) {
      print('❌ Failed to initialize PaymentController: $e');
    }
  }

  /// Process MoMo payment for GymPro
  Future<bool> processGymProPayment({
    required int amount,
    required String orderInfo,
  }) async {
    try {
      isLoading.value = true;
      isProcessingPayment.value = true;
      paymentStatus.value = 'Đang xử lý...';
      paymentMessage.value = 'Vui lòng chờ...';

      // 1. Create payment transaction
      final transaction = PaymentTransaction(
        id: 'GYM_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user_id', // TODO: Get from auth
        membershipCardId: '',
        membershipPurchaseId: '',
        paymentType: PaymentType.service,
        paymentMethod: PaymentMethodType.momo,
        amount: amount.toDouble(),
        status: PaymentStatus.pending,
        description: orderInfo,
        createdAt: DateTime.now(),
      );

      currentTransaction.value = transaction;

      // 2. Create MoMo payment (skip database for now)
      // await _paymentService.createPaymentTransaction(transaction);

      // 3. Create MoMo payment
      final momoResponse = await _momoService.createPayment(
        orderId: transaction.id,
        amount: amount,
        orderInfo: orderInfo,
      );

      if (momoResponse == null || !momoResponse.isSuccess) {
        throw Exception(momoResponse?.message ?? 'Tạo thanh toán thất bại');
      }

      // 4. For web platform, skip app launching and show QR code
      if (kIsWeb) {
        paymentStatus.value = 'Quét mã QR để thanh toán';
        paymentMessage.value = 'Sử dụng ứng dụng MoMo để quét mã QR';

        // Show QR dialog for web
        _showQRCodeDialog(momoResponse);

        currentOrderId.value = transaction.id;
        currentTransactionId.value = momoResponse.orderId;
        return true;
      }

      // 5. Launch MoMo app (mobile only)
      final launched = await _momoService.launchMoMoPayment(momoResponse);
      if (!launched) {
        // If can't launch app, show QR code as fallback
        paymentStatus.value = 'Quét mã QR để thanh toán';
        paymentMessage.value = 'Sử dụng ứng dụng MoMo để quét mã QR';
        _showQRCodeDialog(momoResponse);
      }

      paymentStatus.value = 'Đang chờ thanh toán...';
      paymentMessage.value = 'Vui lòng hoàn tất thanh toán trên ứng dụng MoMo';

      // Update current tracking IDs
      currentOrderId.value = transaction.id;
      currentTransactionId.value = momoResponse.orderId;

      return true;
    } catch (e) {
      print('❌ Error processing payment: $e');
      paymentStatus.value = 'Lỗi thanh toán';
      paymentMessage.value = e.toString();

      _showErrorSnackbar('Lỗi thanh toán', e.toString());
      return false;
    } finally {
      isLoading.value = false;
      isProcessingPayment.value = false;
    }
  }

  /// Handle payment callback from MoMo
  Future<void> _handlePaymentCallback(MoMoCallbackResult result) async {
    try {
      print('📱 Processing payment callback: ${result.orderId}');

      if (currentTransaction.value?.id != result.orderId) {
        print('⚠️ Callback order ID mismatch, ignoring');
        return;
      }

      // Update UI immediately
      if (result.isSuccess) {
        paymentStatus.value = 'Thành công';
        paymentMessage.value = result.statusMessage;

        // Update payment status in database (skip for now)
        // await _paymentService.updatePaymentStatus(
        //   result.orderId,
        //   PaymentStatus.completed
        // );

        _showSuccessDialog(result);
      } else {
        paymentStatus.value = 'Thất bại';
        paymentMessage.value = result.statusMessage;

        // Update payment status in database (skip for now)
        // await _paymentService.updatePaymentStatus(
        //   result.orderId,
        //   PaymentStatus.failed
        // );

        _showFailureDialog(result);
      }
    } catch (e) {
      print('❌ Error handling payment callback: $e');
      paymentStatus.value = 'Lỗi xử lý';
      paymentMessage.value = 'Có lỗi xảy ra khi xử lý kết quả thanh toán';
    }
  }

  /// Show success payment dialog
  void _showSuccessDialog(MoMoCallbackResult result) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Thanh toán thành công'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mã giao dịch: ${result.orderId}'),
            SizedBox(height: 8),
            Text('Số tiền: ${result.amount.toStringAsFixed(0)} VNĐ'),
            SizedBox(height: 8),
            Text('Thời gian: ${DateTime.now().toString().substring(0, 19)}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Get.back(), child: Text('Đóng'))],
      ),
    );
  }

  /// Show failure payment dialog
  void _showFailureDialog(MoMoCallbackResult result) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Thanh toán thất bại'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lý do: ${result.statusMessage}'),
            SizedBox(height: 8),
            Text('Mã lỗi: ${result.resultCode}'),
            if (result.orderId.isNotEmpty) ...[
              SizedBox(height: 8),
              Text('Mã đơn hàng: ${result.orderId}'),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Thử lại thanh toán
              if (currentTransaction.value != null) {
                processGymProPayment(
                  amount: currentTransaction.value!.amount.toInt(),
                  orderInfo:
                      currentTransaction.value!.description ?? 'Thanh toán lại',
                );
              }
            },
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Show QR code dialog for payment
  void _showQRCodeDialog(MoMoPaymentResponse paymentResponse) {
    Get.dialog(
      AlertDialog(
        title: Text('Thanh toán MoMo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (paymentResponse.qrCodeUrl != null &&
                paymentResponse.qrCodeUrl!.isNotEmpty) ...[
              Text('Quét mã QR bằng ứng dụng MoMo:'),
              SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  paymentResponse.qrCodeUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        Text('Không thể tải QR code'),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
            ] else ...[
              Text('Mở ứng dụng MoMo và thanh toán bằng mã:'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  paymentResponse.orderId,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 16),
            ],
            Text(
              'Thanh toán sẽ được xử lý tự động sau khi hoàn tất.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Đóng')),
          if (paymentResponse.payUrl != null &&
              paymentResponse.payUrl!.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                // Try to open MoMo web payment
                launchUrl(Uri.parse(paymentResponse.payUrl!));
              },
              child: Text('Mở MoMo'),
            ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: Duration(seconds: 3),
    );
  }

  /// Update payment amount (for test UI)
  void updateAmount(int amount) {
    paymentAmount.value = amount;
  }

  /// Update order info (for test UI)
  void updateOrderInfo(String info) {
    orderInfo.value = info;
  }

  /// Process payment with current form values
  Future<void> processPayment({int? amount, String? orderInfo}) async {
    final finalAmount = amount ?? paymentAmount.value;
    final finalOrderInfo = orderInfo ?? this.orderInfo.value;

    await processGymProPayment(amount: finalAmount, orderInfo: finalOrderInfo);
  }

  /// Reset payment state
  void resetPaymentState() {
    currentTransaction.value = null;
    paymentStatus.value = '';
    paymentMessage.value = '';
    currentOrderId.value = '';
    currentTransactionId.value = '';
    isLoading.value = false;
    isProcessingPayment.value = false;
  }
}
