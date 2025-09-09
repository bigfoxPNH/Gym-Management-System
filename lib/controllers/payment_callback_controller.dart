import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_transaction.dart';
import '../services/webhook_service.dart';
import '../services/payment_service.dart';

class PaymentCallbackController extends GetxController {
  final WebhookService _webhookService = WebhookService();
  final PaymentService _paymentService = PaymentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable states
  final RxString currentOrderId = ''.obs;
  final Rx<PaymentStatus> paymentStatus = PaymentStatus.pending.obs;
  final RxBool isProcessingCallback = false.obs;
  final RxString statusMessage = ''.obs;

  /// Process Banking callback từ webhook
  Future<Map<String, dynamic>> processBankingCallback(
    Map<String, dynamic> callbackData,
  ) async {
    try {
      isProcessingCallback.value = true;

      // Extract orderId từ callback
      final orderId = callbackData['orderId'] ?? '';
      currentOrderId.value = orderId;

      print('Processing Banking callback for order: $orderId');
      print('Callback data: $callbackData');

      // Log webhook activity
      await _webhookService.logWebhookActivity(
        provider: 'banking',
        type: 'callback',
        data: callbackData,
        success: true,
      );

      // Check for duplicate webhook
      final isDuplicate = await _webhookService.isDuplicateWebhook(
        provider: 'banking',
        transactionId: orderId,
      );

      if (isDuplicate) {
        print('Duplicate Banking callback detected, ignoring');
        return {'status': 'success', 'message': 'Already processed'};
      }

      // Handle callback
      final result = await _webhookService.handleBankingCallback(callbackData);

      // Update local state
      final resultCode = callbackData['resultCode'] ?? -1;
      if (resultCode == 0) {
        paymentStatus.value = PaymentStatus.completed;
        statusMessage.value = 'Thanh toán thành công';

        // Trigger success notifications
        _notifyPaymentSuccess(orderId);
      } else {
        paymentStatus.value = PaymentStatus.failed;
        statusMessage.value = callbackData['message'] ?? 'Thanh toán thất bại';

        // Trigger failure notifications
        _notifyPaymentFailure(orderId, statusMessage.value);
      }

      return result;
    } catch (e) {
      print('Error processing Banking callback: $e');
      paymentStatus.value = PaymentStatus.failed;
      statusMessage.value = 'Lỗi xử lý callback';

      return {'status': 'error', 'message': 'System Error: $e'};
    } finally {
      isProcessingCallback.value = false;
    }
  }

  /// Process return URL khi user quay lại app
  Future<void> processReturnUrl({
    required String provider,
    required Map<String, dynamic> returnData,
  }) async {
    try {
      print('Processing return URL from $provider: $returnData');

      final result = await _webhookService.processReturnUrl(
        provider: provider,
        returnData: returnData,
      );

      currentOrderId.value = result['orderId'] ?? '';

      if (result['success'] == true) {
        paymentStatus.value = PaymentStatus.completed;
        statusMessage.value = result['message'] ?? 'Thanh toán thành công';

        // Show success message to user
        Get.snackbar(
          'Thành công',
          statusMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      } else {
        paymentStatus.value = PaymentStatus.failed;
        statusMessage.value = result['message'] ?? 'Thanh toán thất bại';

        // Show error message to user
        Get.snackbar(
          'Thất bại',
          statusMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      print('Error processing return URL: $e');
      paymentStatus.value = PaymentStatus.failed;
      statusMessage.value = 'Lỗi xử lý kết quả thanh toán';

      Get.snackbar(
        'Lỗi',
        statusMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Kiểm tra trạng thái thanh toán theo orderId
  Future<void> checkPaymentStatus(String orderId) async {
    try {
      final status = await _webhookService.getPaymentStatus(orderId);

      if (status != null) {
        currentOrderId.value = orderId;

        final statusString = status['status'] ?? 'pending';
        paymentStatus.value = PaymentStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusString,
          orElse: () => PaymentStatus.pending,
        );

        statusMessage.value = _getStatusMessage(paymentStatus.value);
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  /// Listen to payment status changes in real-time
  Stream<PaymentTransaction?> watchPaymentStatus(String orderId) {
    return _firestore
        .collection('payment_transactions')
        .where('transactionId', isEqualTo: orderId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return PaymentTransaction.fromMap(snapshot.docs.first.data());
          }
          return null;
        });
  }

  /// Notify payment success
  void _notifyPaymentSuccess(String orderId) {
    print('Payment success notification for order: $orderId');

    // TODO: Implement push notifications
    // TODO: Send email confirmation
    // TODO: Update user's membership status

    // Update UI
    Get.snackbar(
      'Thanh toán thành công!',
      'Đơn hàng $orderId đã được thanh toán thành công',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 5),
    );
  }

  /// Notify payment failure
  void _notifyPaymentFailure(String orderId, String reason) {
    print('Payment failure notification for order: $orderId - Reason: $reason');

    // TODO: Implement push notifications
    // TODO: Send failure email

    // Update UI
    Get.snackbar(
      'Thanh toán thất bại',
      'Đơn hàng $orderId: $reason',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 5),
    );
  }

  /// Get status message
  String _getStatusMessage(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Đang chờ thanh toán';
      case PaymentStatus.processing:
        return 'Đang xử lý thanh toán';
      case PaymentStatus.completed:
        return 'Thanh toán thành công';
      case PaymentStatus.failed:
        return 'Thanh toán thất bại';
      case PaymentStatus.cancelled:
        return 'Đã hủy thanh toán';
      case PaymentStatus.expired:
        return 'Đã hết hạn thanh toán';
    }
  }

  /// Reset controller state
  void reset() {
    currentOrderId.value = '';
    paymentStatus.value = PaymentStatus.pending;
    statusMessage.value = '';
    isProcessingCallback.value = false;
  }

  /// Simulate webhook callback for testing
  Future<void> simulateCallback({
    required String orderId,
    required bool success,
    String? message,
  }) async {
    final mockCallback = {
      'partnerCode': 'MOMO',
      'orderId': orderId,
      'requestId': 'REQ_${DateTime.now().millisecondsSinceEpoch}',
      'amount': 50000,
      'orderInfo': 'Test payment',
      'orderType': 'momo_wallet',
      'transId': success
          ? 'TRANS_${DateTime.now().millisecondsSinceEpoch}'
          : '',
      'resultCode': success ? 0 : 1006,
      'message': message ?? (success ? 'Successful.' : 'Transaction failed'),
      'payType': 'qr',
      'responseTime': DateTime.now().millisecondsSinceEpoch,
      'extraData': '',
      'signature': 'mock_signature_for_testing',
    };

    await processBankingCallback(mockCallback);
  }
}
