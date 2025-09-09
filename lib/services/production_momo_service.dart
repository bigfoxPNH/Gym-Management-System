import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/momo_config.dart';

class PaymentRequest {
  final String orderId;
  final int amount;
  final String orderInfo;

  PaymentRequest({
    required this.orderId,
    required this.amount,
    required this.orderInfo,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'amount': amount,
    'orderInfo': orderInfo,
  };
}

class PaymentResponse {
  final bool success;
  final String orderId;
  final String? payUrl;
  final String? qrCodeUrl;
  final String? deepLink;
  final int amount;
  final String orderInfo;
  final String? message;
  final String? error;

  PaymentResponse({
    required this.success,
    required this.orderId,
    this.payUrl,
    this.qrCodeUrl,
    this.deepLink,
    required this.amount,
    required this.orderInfo,
    this.message,
    this.error,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      orderId: json['orderId'] ?? '',
      payUrl: json['payUrl'],
      qrCodeUrl: json['qrCodeUrl'],
      deepLink: json['deepLink'],
      amount: json['amount'] ?? 0,
      orderInfo: json['orderInfo'] ?? '',
      message: json['message'],
      error: json['error'],
    );
  }
}

class PaymentStatus {
  final bool success;
  final String orderId;
  final String status; // pending, success, failed, expired
  final int amount;
  final String orderInfo;
  final String? transId;
  final String message;

  PaymentStatus({
    required this.success,
    required this.orderId,
    required this.status,
    required this.amount,
    required this.orderInfo,
    this.transId,
    required this.message,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    return PaymentStatus(
      success: json['success'] ?? false,
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? 'unknown',
      amount: json['amount'] ?? 0,
      orderInfo: json['orderInfo'] ?? '',
      transId: json['transId'],
      message: json['message'] ?? '',
    );
  }

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isExpired => status == 'expired';
}

class ProductionMoMoService {
  static final ProductionMoMoService _instance =
      ProductionMoMoService._internal();
  factory ProductionMoMoService() => _instance;
  ProductionMoMoService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: MoMoConfig.requestTimeout,
      receiveTimeout: MoMoConfig.requestTimeout,
      sendTimeout: MoMoConfig.requestTimeout,
    ),
  );

  Timer? _pollingTimer;
  StreamController<PaymentStatus>? _statusController;

  /// Create a new payment via backend
  Future<PaymentResponse> createPayment({
    required String orderId,
    required int amount,
    required String orderInfo,
  }) async {
    try {
      print(
        '🔄 Creating payment via backend: ${MoMoConfig.createPaymentEndpoint}',
      );

      final request = PaymentRequest(
        orderId: orderId,
        amount: amount,
        orderInfo: orderInfo,
      );

      final response = await _dio.post(
        MoMoConfig.createPaymentEndpoint,
        data: request.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        print('✅ Payment created successfully');
        return PaymentResponse.fromJson(response.data);
      } else {
        print('❌ Payment creation failed: ${response.statusCode}');
        return PaymentResponse(
          success: false,
          orderId: orderId,
          amount: amount,
          orderInfo: orderInfo,
          error: 'Failed to create payment: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Network error creating payment: ${e.message}');
      return PaymentResponse(
        success: false,
        orderId: orderId,
        amount: amount,
        orderInfo: orderInfo,
        error: 'Network error: ${e.message}',
      );
    } catch (e) {
      print('❌ Unexpected error creating payment: $e');
      return PaymentResponse(
        success: false,
        orderId: orderId,
        amount: amount,
        orderInfo: orderInfo,
        error: 'Unexpected error: $e',
      );
    }
  }

  /// Get payment status from backend
  Future<PaymentStatus> getPaymentStatus(String orderId) async {
    try {
      final response = await _dio.get(
        '${MoMoConfig.paymentStatusEndpoint}/$orderId',
      );

      if (response.statusCode == 200) {
        return PaymentStatus.fromJson(response.data);
      } else {
        return PaymentStatus(
          success: false,
          orderId: orderId,
          status: 'unknown',
          amount: 0,
          orderInfo: '',
          message: 'Failed to get status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('❌ Network error getting status: ${e.message}');
      return PaymentStatus(
        success: false,
        orderId: orderId,
        status: 'unknown',
        amount: 0,
        orderInfo: '',
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      print('❌ Unexpected error getting status: $e');
      return PaymentStatus(
        success: false,
        orderId: orderId,
        status: 'unknown',
        amount: 0,
        orderInfo: '',
        message: 'Unexpected error: $e',
      );
    }
  }

  /// Start polling payment status
  Stream<PaymentStatus> pollPaymentStatus(String orderId) {
    _statusController = StreamController<PaymentStatus>.broadcast();

    int attempt = 0;

    _pollingTimer = Timer.periodic(MoMoConfig.pollingInterval, (timer) async {
      attempt++;

      if (attempt > MoMoConfig.maxPollingAttempts) {
        print('⏰ Polling timeout for order: $orderId');
        _statusController?.add(
          PaymentStatus(
            success: false,
            orderId: orderId,
            status: 'expired',
            amount: 0,
            orderInfo: '',
            message: 'Payment timeout',
          ),
        );
        stopPolling();
        return;
      }

      try {
        print('🔍 Polling attempt $attempt for order: $orderId');
        final status = await getPaymentStatus(orderId);

        _statusController?.add(status);

        // Stop polling if payment is completed
        if (status.isSuccess || status.isFailed || status.isExpired) {
          print('✅ Payment completed with status: ${status.status}');
          stopPolling();
        }
      } catch (e) {
        print('❌ Error during polling: $e');
      }
    });

    return _statusController!.stream;
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _statusController?.close();
    _statusController = null;
  }

  /// Try to launch MoMo app (mobile only)
  Future<bool> launchMoMoApp(String? deepLink) async {
    if (kIsWeb || deepLink == null || deepLink.isEmpty) {
      return false;
    }

    try {
      // Try to launch MoMo app with deep link
      // Implementation depends on your app_links/url_launcher setup
      print('🚀 Attempting to launch MoMo app with: $deepLink');

      // This is a placeholder - implement based on your deep link handling
      // You might use url_launcher package here

      return false; // Return false to show QR code as fallback
    } catch (e) {
      print('❌ Failed to launch MoMo app: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopPolling();
    _dio.close();
  }
}
