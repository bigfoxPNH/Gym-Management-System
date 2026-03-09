import 'package:cloud_firestore/cloud_firestore.dart';

/// Service để xử lý webhook callbacks từ các payment gateways
class WebhookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Handle banking callback (for future banking integrations)
  Future<Map<String, dynamic>> handleBankingCallback(
    Map<String, dynamic> callbackData,
  ) async {
    try {
      print('Received Banking callback: $callbackData');

      // TODO: Implement banking callback handling
      // This would be for banking APIs

      return {'status': 'success', 'message': 'Banking callback processed'};
    } catch (e) {
      print('Error handling Banking callback: $e');
      return {'status': 'error', 'message': 'Banking callback failed'};
    }
  }

  /// Log webhook activity for debugging
  Future<void> logWebhookActivity({
    required String provider,
    required String type,
    required Map<String, dynamic> data,
    required bool success,
    String? error,
  }) async {
    try {
      await _firestore.collection('webhook_logs').add({
        'provider': provider, // 'banking', etc.
        'type': type, // 'callback', 'return', etc.
        'data': data,
        'success': success,
        'error': error,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging webhook activity: $e');
    }
  }

  /// Verify webhook authenticity
  bool verifyWebhookSignature({
    required String provider,
    required Map<String, dynamic> data,
    required String signature,
  }) {
    switch (provider.toLowerCase()) {
      case 'banking':
        // TODO: Implement banking signature verification
        return true;
      default:
        return false;
    }
  }

  /// Check if webhook is duplicate
  Future<bool> isDuplicateWebhook({
    required String provider,
    required String transactionId,
    Duration timeWindow = const Duration(minutes: 10),
  }) async {
    try {
      final cutoffTime = DateTime.now().subtract(timeWindow);

      final querySnapshot = await _firestore
          .collection('webhook_logs')
          .where('provider', isEqualTo: provider)
          .where('data.orderId', isEqualTo: transactionId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffTime))
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking duplicate webhook: $e');
      return false;
    }
  }

  /// Process return URL (when user returns from payment gateway)
  Future<Map<String, dynamic>> processReturnUrl({
    required String provider,
    required Map<String, dynamic> returnData,
  }) async {
    try {
      print('Processing return URL for $provider: $returnData');

      // Log return activity
      await logWebhookActivity(
        provider: provider,
        type: 'return',
        data: returnData,
        success: true,
      );

      // Extract order information
      final orderId = returnData['orderId'] ?? '';

      // Determine payment result
      bool isSuccess = false;
      String message = 'Payment failed';

      switch (provider.toLowerCase()) {
        case 'banking':
          // TODO: Implement banking return logic
          break;
      }

      return {
        'success': isSuccess,
        'message': message,
        'orderId': orderId,
        'provider': provider,
        'data': returnData,
      };
    } catch (e) {
      print('Error processing return URL: $e');
      return {
        'success': false,
        'message': 'Error processing payment return',
        'error': e.toString(),
      };
    }
  }

  /// Get payment status by order ID
  Future<Map<String, dynamic>?> getPaymentStatus(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('payment_transactions')
          .where('transactionId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return {
          'orderId': orderId,
          'status': data['status'],
          'amount': data['amount'],
          'paymentMethod': data['paymentMethod'],
          'createdAt': data['createdAt'],
          'completedAt': data['completedAt'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting payment status: $e');
      return null;
    }
  }
}
