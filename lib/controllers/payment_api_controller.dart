import 'package:get/get.dart';
import '../controllers/payment_callback_controller.dart';

/// Demo API endpoints để test webhook callbacks
/// Trong thực tế, đây sẽ là các endpoint trên server backend của bạn
class PaymentApiController extends GetxController {
  final PaymentCallbackController _callbackController =
      Get.find<PaymentCallbackController>();

  /// Endpoint nhận MoMo callback (POST /api/payment/momo/callback)
  Future<Map<String, dynamic>> handleMoMoCallback(
    Map<String, dynamic> body,
  ) async {
    try {
      print('=== MoMo Callback Received ===');
      print('Body: $body');

      // Process the callback
      final result = await _callbackController.processMoMoCallback(body);

      print('=== MoMo Callback Result ===');
      print('Result: $result');

      return result;
    } catch (e) {
      print('Error in MoMo callback endpoint: $e');
      return {'RspCode': '99', 'Message': 'System Error'};
    }
  }

  /// Endpoint nhận Banking callback (POST /api/payment/banking/callback)
  Future<Map<String, dynamic>> handleBankingCallback(
    Map<String, dynamic> body,
  ) async {
    try {
      print('=== Banking Callback Received ===');
      print('Body: $body');

      // TODO: Process banking callback
      // Similar to MoMo but for banking

      return {'status': 'success', 'message': 'Banking callback processed'};
    } catch (e) {
      print('Error in Banking callback endpoint: $e');
      return {'status': 'error', 'message': 'System Error'};
    }
  }

  /// Return URL endpoint (GET /api/payment/momo/return)
  Future<Map<String, dynamic>> handleMoMoReturn(
    Map<String, String> queryParams,
  ) async {
    try {
      print('=== MoMo Return URL ===');
      print('Query params: $queryParams');

      await _callbackController.processReturnUrl(
        provider: 'momo',
        returnData: Map<String, dynamic>.from(queryParams),
      );

      return {
        'status': 'success',
        'message': 'Return processed',
        'redirect': '/membership/purchase-success',
      };
    } catch (e) {
      print('Error in MoMo return endpoint: $e');
      return {
        'status': 'error',
        'message': 'Error processing return',
        'redirect': '/membership/purchase-failed',
      };
    }
  }

  /// Test webhook endpoint để simulate callback từ MoMo
  Future<Map<String, dynamic>> testMoMoCallback({
    required String orderId,
    required bool success,
    String? message,
  }) async {
    try {
      print('=== Testing MoMo Callback ===');
      print('OrderId: $orderId, Success: $success');

      // Simulate callback from MoMo
      await _callbackController.simulateCallback(
        orderId: orderId,
        success: success,
        message: message,
      );

      return {'status': 'success', 'message': 'Test callback processed'};
    } catch (e) {
      print('Error in test callback: $e');
      return {'status': 'error', 'message': 'Test callback failed'};
    }
  }

  /// Get payment status endpoint (GET /api/payment/status/:orderId)
  Future<Map<String, dynamic>?> getPaymentStatus(String orderId) async {
    try {
      await _callbackController.checkPaymentStatus(orderId);

      return {
        'orderId': _callbackController.currentOrderId.value,
        'status': _callbackController.paymentStatus.value.name,
        'message': _callbackController.statusMessage.value,
        'isProcessing': _callbackController.isProcessingCallback.value,
      };
    } catch (e) {
      print('Error getting payment status: $e');
      return null;
    }
  }
}

/// Utility class để mô phỏng HTTP server endpoints
class MockPaymentServer {
  static final PaymentApiController _controller = PaymentApiController();

  /// Mô phỏng việc nhận POST request từ MoMo
  static Future<void> simulateMoMoWebhook({
    required String orderId,
    required bool paymentSuccess,
    String? errorMessage,
  }) async {
    print('\n🚀 === SIMULATING MOMO WEBHOOK ===');

    // Mock MoMo callback data
    final mockCallbackData = {
      'partnerCode': 'MOMO',
      'orderId': orderId,
      'requestId': 'REQ_${DateTime.now().millisecondsSinceEpoch}',
      'amount': 50000,
      'orderInfo': 'Thanh toán thẻ tập gym',
      'orderType': 'momo_wallet',
      'transId': paymentSuccess
          ? 'TRANS_${DateTime.now().millisecondsSinceEpoch}'
          : '',
      'resultCode': paymentSuccess ? 0 : 1006,
      'message': paymentSuccess
          ? 'Successful.'
          : (errorMessage ?? 'Transaction failed'),
      'payType': 'qr',
      'responseTime': DateTime.now().millisecondsSinceEpoch,
      'extraData': '',
      'signature': 'mock_signature_${DateTime.now().millisecondsSinceEpoch}',
    };

    // Call the webhook endpoint
    final result = await _controller.handleMoMoCallback(mockCallbackData);

    print('📨 Webhook response: $result');
    print('✅ === WEBHOOK SIMULATION COMPLETE ===\n');
  }

  /// Mô phỏng user quay lại app sau thanh toán
  static Future<void> simulateReturnUrl({
    required String orderId,
    required bool paymentSuccess,
  }) async {
    print('\n🔄 === SIMULATING RETURN URL ===');

    final returnParams = {
      'partnerCode': 'MOMO',
      'orderId': orderId,
      'requestId': 'REQ_${DateTime.now().millisecondsSinceEpoch}',
      'amount': '50000',
      'orderInfo': 'Thanh toán thẻ tập gym',
      'orderType': 'momo_wallet',
      'transId': paymentSuccess
          ? 'TRANS_${DateTime.now().millisecondsSinceEpoch}'
          : '',
      'resultCode': paymentSuccess ? '0' : '1006',
      'message': paymentSuccess ? 'Successful.' : 'Transaction failed',
      'payType': 'qr',
      'responseTime': DateTime.now().millisecondsSinceEpoch.toString(),
      'signature': 'mock_signature_${DateTime.now().millisecondsSinceEpoch}',
    };

    final result = await _controller.handleMoMoReturn(returnParams);

    print('🏠 Return URL response: $result');
    print('✅ === RETURN URL SIMULATION COMPLETE ===\n');
  }
}
