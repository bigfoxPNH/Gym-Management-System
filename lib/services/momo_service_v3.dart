import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../models/payment_models.dart';

// MoMo Backend Proxy Configuration
class MoMoConfig {
  // Backend proxy server endpoint (thay vì gọi MoMo trực tiếp)
  static const String endpoint =
      'http://192.168.23.1:3000/api/momo/create-payment';
  static const String queryEndpoint = 'http://192.168.23.1:3000/api/momo/query';

  // Production: thay localhost bằng domain thật của bạn
  // static const String endpoint = 'https://your-backend.herokuapp.com/api/momo/create-payment';
  // static const String queryEndpoint = 'https://your-backend.herokuapp.com/api/momo/query';

  static const String requestType = 'captureWallet';
  static const String lang = 'vi';
}

class MoMoServiceV3 {
  final Dio _dio = Dio();

  MoMoServiceV3() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🔄 MoMo Backend Request: ${options.method} ${options.uri}');
          print('📤 Request Data: ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ MoMo Backend Response: ${response.statusCode}');
          print('📥 Response Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ MoMo Backend Error: ${error.message}');
          print('Error Type: ${error.type}');
          if (error.response != null) {
            print('Error Response: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Tạo thanh toán MoMo qua backend proxy
  /// Backend sẽ gọi MoMo API thay cho Flutter để bypass CORS
  Future<PaymentResponse> createPayment({
    required String orderId,
    required String orderInfo,
    required int amount,
    String? extraData,
  }) async {
    try {
      // Gọi backend proxy thay vì MoMo trực tiếp
      final requestBody = {
        'orderId': orderId,
        'orderInfo': orderInfo,
        'amount': amount,
        'extraData': extraData ?? '',
        'requestType': MoMoConfig.requestType,
        'lang': MoMoConfig.lang,
      };

      print('🚀 Creating MoMo payment through backend proxy...');
      print('📋 Request: $requestBody');

      final response = await _dio.post(
        MoMoConfig.endpoint,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        print('🎉 MoMo Response: $data');

        return PaymentResponse.fromJson(data);
      } else {
        throw Exception(
          'Invalid response from backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error creating MoMo payment: $e');

      if (e is DioException) {
        return _handleDioException(e);
      }

      throw Exception('Không thể tạo thanh toán MoMo: ${e.toString()}');
    }
  }

  /// Truy vấn trạng thái thanh toán qua backend proxy
  Future<PaymentQueryResponse> queryPayment({required String orderId}) async {
    try {
      final requestBody = {'orderId': orderId};

      print('🔍 Querying MoMo payment through backend proxy...');
      print('📋 Request: $requestBody');

      final response = await _dio.post(
        MoMoConfig.queryEndpoint,
        data: requestBody,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        print('📊 MoMo Query Response: $data');

        return PaymentQueryResponse.fromJson(data);
      } else {
        throw Exception(
          'Invalid response from backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error querying MoMo payment: $e');

      if (e is DioException) {
        return _handleQueryDioException(e);
      }

      throw Exception('Không thể truy vấn thanh toán MoMo: ${e.toString()}');
    }
  }

  /// Xử lý lỗi DioException cho create payment
  PaymentResponse _handleDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception('⏱️ Kết nối tới server bị timeout. Vui lòng thử lại.');
    } else if (e.type == DioExceptionType.connectionError) {
      throw Exception(
        '🌐 Không thể kết nối tới server backend.\n'
        '💡 Hướng dẫn:\n'
        '1. Kiểm tra server backend có đang chạy không\n'
        '2. Chạy: cd backend && npm start\n'
        '3. Kiểm tra URL: http://192.168.23.1:3000',
      );
    } else if (e.response?.statusCode == 400) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map
          ? errorData['error'] ?? 'Yêu cầu không hợp lệ'
          : 'Yêu cầu không hợp lệ';
      throw Exception('❌ $errorMessage');
    } else if (e.response?.statusCode == 500) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map
          ? errorData['error'] ?? 'Lỗi server nội bộ'
          : 'Lỗi server nội bộ';
      throw Exception('🔥 Server Error: $errorMessage');
    }

    throw Exception('💥 Không thể tạo thanh toán MoMo: ${e.toString()}');
  }

  /// Xử lý lỗi DioException cho query payment
  PaymentQueryResponse _handleQueryDioException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      throw Exception('⏱️ Kết nối tới server bị timeout. Vui lòng thử lại.');
    } else if (e.type == DioExceptionType.connectionError) {
      throw Exception(
        '🌐 Không thể kết nối tới server backend. Kiểm tra server có đang chạy không.',
      );
    }

    throw Exception('💥 Không thể truy vấn thanh toán MoMo: ${e.toString()}');
  }

  /// Verify callback từ MoMo webhook (backend đã verify signature rồi)
  bool verifyCallback(Map<String, dynamic> callbackData) {
    try {
      print('🔐 Verifying MoMo callback: $callbackData');

      // Backend đã verify signature rồi, chỉ cần kiểm tra resultCode
      final resultCode = callbackData['resultCode'];
      final isSuccess = resultCode == 0; // 0 = success

      print(
        isSuccess
            ? '✅ Callback verified successfully'
            : '❌ Callback verification failed',
      );
      return isSuccess;
    } catch (e) {
      print('💥 Error verifying MoMo callback: $e');
      return false;
    }
  }

  /// Handle callback data
  PaymentCallbackData? handleCallback(Map<String, dynamic> data) {
    try {
      return PaymentCallbackData.fromJson(data);
    } catch (e) {
      print('💥 Error handling MoMo callback: $e');
      return null;
    }
  }

  /// Generate unique order ID
  String generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'ORDER_${timestamp}_$random';
  }

  /// Generate request ID
  String generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'REQ_${timestamp}_$random';
  }

  /// Kiểm tra backend server có sẵn sàng không
  Future<bool> checkBackendHealth() async {
    try {
      final healthUrl = MoMoConfig.endpoint.replaceAll(
        '/api/momo/create-payment',
        '/health',
      );
      final response = await _dio.get(healthUrl);

      return response.statusCode == 200;
    } catch (e) {
      print('💊 Backend health check failed: $e');
      return false;
    }
  }
}

/// Extension để tạo demo QR (fallback khi backend không available)
extension MoMoServiceDemo on MoMoServiceV3 {
  PaymentResponse createDemoResponse({
    required String orderId,
    required String orderInfo,
    required int amount,
  }) {
    // Tạo QR data giả cho demo
    final qrCodeUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=MOMO_DEMO_$orderId';

    print('🎭 Creating demo MoMo response for testing...');

    return PaymentResponse(
      partnerCode: 'MOMO',
      orderId: orderId,
      requestId: generateRequestId(),
      amount: amount,
      orderInfo: orderInfo,
      orderType: 'momo_wallet',
      transId: DateTime.now().millisecondsSinceEpoch,
      resultCode: 0,
      message: 'Demo payment created successfully',
      payUrl: 'momo://payment?order=$orderId',
      deeplink: 'momo://payment?order=$orderId',
      qrCodeUrl: qrCodeUrl,
      applink: 'momo://payment?order=$orderId',
    );
  }

  /// Tạo fallback response khi backend không available
  Future<PaymentResponse> createPaymentWithFallback({
    required String orderId,
    required String orderInfo,
    required int amount,
    String? extraData,
  }) async {
    try {
      // Thử backend trước
      return await createPayment(
        orderId: orderId,
        orderInfo: orderInfo,
        amount: amount,
        extraData: extraData,
      );
    } catch (e) {
      if (e.toString().contains('Không thể kết nối tới server backend')) {
        print('🎭 Backend không available, chuyển sang demo mode...');
        return createDemoResponse(
          orderId: orderId,
          orderInfo: orderInfo,
          amount: amount,
        );
      }
      rethrow;
    }
  }
}
