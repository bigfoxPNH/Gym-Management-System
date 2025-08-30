import 'dart:async';
import 'package:dio/dio.dart';
import '../config/momo_config.dart';

class PaymentMonitorService {
  static final Dio _dio = Dio();
  static String get _baseUrl => MoMoConfig.backendUrl;

  // Monitor payment status với polling
  static Stream<Map<String, dynamic>> monitorPaymentStatus(
    String orderId,
  ) async* {
    try {
      // Poll every 3 seconds for up to 5 minutes
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(seconds: 3));

        try {
          final response = await _dio.get(
            '$_baseUrl/api/momo/payment-status/$orderId',
          );

          if (response.statusCode == 200) {
            final data = response.data;

            print('🔍 Payment status check: ${data['status']} (${i + 1}/100)');

            yield {
              'orderId': orderId,
              'status': data['status'],
              'success': data['success'],
              'timeRemaining': data['timeRemaining'],
              'isExpired': data['isExpired'],
              'checkCount': i + 1,
            };

            // Stop polling if payment is completed or expired
            if (data['status'] == 'success' ||
                data['status'] == 'expired' ||
                data['status'] == 'failed') {
              print(
                '✅ Payment monitoring completed with status: ${data['status']}',
              );
              break;
            }
          }
        } catch (e) {
          print('❌ Error checking payment status: $e');
          yield {
            'orderId': orderId,
            'status': 'error',
            'success': false,
            'error': e.toString(),
            'checkCount': i + 1,
          };
        }
      }
    } catch (e) {
      print('❌ Payment monitoring error: $e');
      yield {
        'orderId': orderId,
        'status': 'error',
        'success': false,
        'error': e.toString(),
        'checkCount': 0,
      };
    }
  }

  // Create payment on backend
  static Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required int amount,
    required String orderInfo,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/momo/create-payment',
        data: {'orderId': orderId, 'amount': amount, 'orderInfo': orderInfo},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.statusMessage}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Simulate payment success (for testing)
  static Future<Map<String, dynamic>> simulatePaymentSuccess(
    String orderId,
  ) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/api/momo/manual-success/$orderId',
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Payment simulated successfully'};
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.statusMessage}',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get payment URL for web redirect
  static String getPaymentUrl({
    required String orderId,
    required int amount,
    required String orderInfo,
  }) {
    final encodedOrderInfo = Uri.encodeComponent(orderInfo);
    // Luôn trả về URL public nếu là production, ngrok nếu là UAT
    final baseUrl = MoMoConfig.backendUrl;
    return '$baseUrl/payment?orderId=$orderId&amount=$amount&orderInfo=$encodedOrderInfo';
  }
}
