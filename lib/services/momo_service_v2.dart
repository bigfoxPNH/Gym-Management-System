import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_transaction.dart';

// MoMo API Configuration
class MoMoConfig {
  // Backend proxy server endpoint (thay vì gọi MoMo trực tiếp)
  static const String endpoint =
      'http://192.168.23.1:3000/api/momo/create-payment';
  static const String queryEndpoint = 'http://192.168.23.1:3000/api/momo/query';

  // Production: thay localhost bằng domain thật
  // static const String endpoint = 'https://your-backend.com/api/momo/create-payment';
  // static const String queryEndpoint = 'https://your-backend.com/api/momo/query';

  static const String requestType = 'payWithATM';
  static const String lang = 'vi';
}

// MoMo API Models
class MoMoPaymentRequest {
  final String partnerCode;
  final String requestId;
  final int amount;
  final String orderId;
  final String orderInfo;
  final String redirectUrl;
  final String ipnUrl;
  final String requestType;
  final String extraData;
  final String lang;
  final String signature;

  MoMoPaymentRequest({
    required this.partnerCode,
    required this.requestId,
    required this.amount,
    required this.orderId,
    required this.orderInfo,
    required this.redirectUrl,
    required this.ipnUrl,
    required this.requestType,
    required this.extraData,
    required this.lang,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'partnerCode': partnerCode,
      'requestId': requestId,
      'amount': amount,
      'orderId': orderId,
      'orderInfo': orderInfo,
      'redirectUrl': redirectUrl,
      'ipnUrl': ipnUrl,
      'requestType': requestType,
      'extraData': extraData,
      'lang': lang,
      'signature': signature,
    };
  }
}

class MoMoPaymentResponse {
  final String partnerCode;
  final String requestId;
  final String orderId;
  final int amount;
  final int resultCode;
  final String message;
  final String? payUrl;
  final String? qrCodeUrl;
  final String? deeplink;
  final String? deeplinkMiniApp;
  final String signature;

  MoMoPaymentResponse({
    required this.partnerCode,
    required this.requestId,
    required this.orderId,
    required this.amount,
    required this.resultCode,
    required this.message,
    this.payUrl,
    this.qrCodeUrl,
    this.deeplink,
    this.deeplinkMiniApp,
    required this.signature,
  });

  factory MoMoPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MoMoPaymentResponse(
      partnerCode: json['partnerCode'] ?? '',
      requestId: json['requestId'] ?? '',
      orderId: json['orderId'] ?? '',
      amount: json['amount'] ?? 0,
      resultCode: json['resultCode'] ?? -1,
      message: json['message'] ?? '',
      payUrl: json['payUrl'],
      qrCodeUrl: json['qrCodeUrl'],
      deeplink: json['deeplink'],
      deeplinkMiniApp: json['deeplinkMiniApp'],
      signature: json['signature'] ?? '',
    );
  }

  bool get isSuccess => resultCode == 0;
}

// MoMo Callback Model
class MoMoCallback {
  final String partnerCode;
  final String orderId;
  final String requestId;
  final int amount;
  final String orderInfo;
  final String orderType;
  final String transId;
  final int resultCode;
  final String message;
  final String payType;
  final int responseTime;
  final String extraData;
  final String signature;

  MoMoCallback({
    required this.partnerCode,
    required this.orderId,
    required this.requestId,
    required this.amount,
    required this.orderInfo,
    required this.orderType,
    required this.transId,
    required this.resultCode,
    required this.message,
    required this.payType,
    required this.responseTime,
    required this.extraData,
    required this.signature,
  });

  factory MoMoCallback.fromJson(Map<String, dynamic> json) {
    return MoMoCallback(
      partnerCode: json['partnerCode'] ?? '',
      orderId: json['orderId'] ?? '',
      requestId: json['requestId'] ?? '',
      amount: json['amount'] ?? 0,
      orderInfo: json['orderInfo'] ?? '',
      orderType: json['orderType'] ?? '',
      transId: json['transId'] ?? '',
      resultCode: json['resultCode'] ?? -1,
      message: json['message'] ?? '',
      payType: json['payType'] ?? '',
      responseTime: json['responseTime'] ?? 0,
      extraData: json['extraData'] ?? '',
      signature: json['signature'] ?? '',
    );
  }

  bool get isSuccess => resultCode == 0;

  Map<String, dynamic> toJson() {
    return {
      'partnerCode': partnerCode,
      'orderId': orderId,
      'requestId': requestId,
      'amount': amount,
      'orderInfo': orderInfo,
      'orderType': orderType,
      'transId': transId,
      'resultCode': resultCode,
      'message': message,
      'payType': payType,
      'responseTime': responseTime,
      'extraData': extraData,
      'signature': signature,
    };
  }
}

class MoMoService {
  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate HMAC SHA256 signature for MoMo API
  String _generateSignature(String rawData) {
    var key = utf8.encode(MoMoConfig.secretKey);
    var bytes = utf8.encode(rawData);
    var hmacSha256 = Hmac(sha256, key);
    var digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Generate unique request ID
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'MM$timestamp$random';
  }

  /// Create MoMo payment request
  Future<MoMoPaymentResponse?> createPayment({
    required String orderId,
    required double amount,
    required String orderInfo,
    String extraData = '',
  }) async {
    try {
      final requestId = _generateRequestId();
      final amountInt = amount.toInt();

      // Create raw signature data according to MoMo specification
      final rawSignature =
          'accessKey=${MoMoConfig.accessKey}'
          '&amount=$amountInt'
          '&extraData=$extraData'
          '&ipnUrl=${MoMoConfig.notifyUrl}'
          '&orderId=$orderId'
          '&orderInfo=$orderInfo'
          '&partnerCode=${MoMoConfig.partnerCode}'
          '&redirectUrl=${MoMoConfig.returnUrl}'
          '&requestId=$requestId'
          '&requestType=${MoMoConfig.requestType}';

      final signature = _generateSignature(rawSignature);

      final request = MoMoPaymentRequest(
        partnerCode: MoMoConfig.partnerCode,
        requestId: requestId,
        amount: amountInt,
        orderId: orderId,
        orderInfo: orderInfo,
        redirectUrl: MoMoConfig.returnUrl,
        ipnUrl: MoMoConfig.notifyUrl,
        requestType: MoMoConfig.requestType,
        extraData: extraData,
        lang: MoMoConfig.lang,
        signature: signature,
      );

      print('MoMo Request: ${request.toJson()}');

      final response = await _dio.post(
        MoMoConfig.endpoint,
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final momoResponse = MoMoPaymentResponse.fromJson(response.data);
        print('MoMo Response: ${response.data}');

        if (momoResponse.isSuccess) {
          return momoResponse;
        } else {
          print('MoMo Payment Creation Failed: ${momoResponse.message}');
          return null;
        }
      } else {
        print('MoMo API Error: ${response.statusCode} - ${response.data}');
        return null;
      }
    } catch (e) {
      print('MoMo Service Error: $e');
      return null;
    }
  }

  /// Verify MoMo callback signature
  bool verifyCallback(MoMoCallback callback) {
    try {
      final rawSignature =
          'accessKey=${MoMoConfig.accessKey}'
          '&amount=${callback.amount}'
          '&extraData=${callback.extraData}'
          '&message=${callback.message}'
          '&orderId=${callback.orderId}'
          '&orderInfo=${callback.orderInfo}'
          '&orderType=${callback.orderType}'
          '&partnerCode=${callback.partnerCode}'
          '&payType=${callback.payType}'
          '&requestId=${callback.requestId}'
          '&responseTime=${callback.responseTime}'
          '&resultCode=${callback.resultCode}'
          '&transId=${callback.transId}';

      final expectedSignature = _generateSignature(rawSignature);
      final isValid = expectedSignature == callback.signature;

      print('Callback Signature Verification:');
      print('Raw data: $rawSignature');
      print('Expected: $expectedSignature');
      print('Received: ${callback.signature}');
      print('Valid: $isValid');

      return isValid;
    } catch (e) {
      print('Signature verification error: $e');
      return false;
    }
  }

  /// Handle MoMo callback and update payment status
  Future<bool> handleCallback(Map<String, dynamic> callbackData) async {
    try {
      final callback = MoMoCallback.fromJson(callbackData);

      // Verify signature
      if (!verifyCallback(callback)) {
        print('Invalid callback signature');
        return false;
      }

      // Update payment transaction status
      await _updatePaymentStatus(callback);

      return true;
    } catch (e) {
      print('Error handling MoMo callback: $e');
      return false;
    }
  }

  /// Update payment transaction status in Firestore
  Future<void> _updatePaymentStatus(MoMoCallback callback) async {
    try {
      // Find payment transaction by orderId
      final querySnapshot = await _firestore
          .collection('payment_transactions')
          .where('transactionId', isEqualTo: callback.orderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final transaction = PaymentTransaction.fromMap(doc.data());

        // Update transaction status based on MoMo result
        PaymentStatus newStatus;
        DateTime? completedAt;

        if (callback.isSuccess) {
          newStatus = PaymentStatus.completed;
          completedAt = DateTime.now();
        } else {
          newStatus = PaymentStatus.failed;
        }

        // Update payment transaction
        final updatedTransaction = transaction.copyWith(
          status: newStatus,
          transactionId: callback.transId,
          completedAt: completedAt,
          metadata: {
            ...transaction.metadata ?? {},
            'momoCallback': callback.toJson(),
          },
        );

        await _firestore
            .collection('payment_transactions')
            .doc(doc.id)
            .update(updatedTransaction.toMap());

        // If payment successful, update membership purchase status
        if (callback.isSuccess) {
          await _updateMembershipPurchaseStatus(
            transaction.membershipPurchaseId,
          );
        }

        print(
          'Payment transaction updated: ${doc.id} - Status: ${newStatus.name}',
        );
      } else {
        print('Payment transaction not found for orderId: ${callback.orderId}');
      }
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  /// Update membership purchase status to active
  Future<void> _updateMembershipPurchaseStatus(String purchaseId) async {
    try {
      await _firestore
          .collection('membership_purchases')
          .doc(purchaseId)
          .update({
            'status': 'active',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      print('Membership purchase activated: $purchaseId');
    } catch (e) {
      print('Error updating membership purchase: $e');
    }
  }

  /// Query payment status from MoMo
  Future<Map<String, dynamic>?> queryPaymentStatus({
    required String orderId,
    required String requestId,
  }) async {
    try {
      final rawSignature =
          'accessKey=${MoMoConfig.accessKey}'
          '&orderId=$orderId'
          '&partnerCode=${MoMoConfig.partnerCode}'
          '&requestId=$requestId';

      final signature = _generateSignature(rawSignature);

      final queryData = {
        'partnerCode': MoMoConfig.partnerCode,
        'requestId': requestId,
        'orderId': orderId,
        'signature': signature,
        'lang': MoMoConfig.lang,
      };

      final response = await _dio.post(
        MoMoConfig.queryEndpoint,
        data: queryData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error querying MoMo payment status: $e');
      return null;
    }
  }
}
