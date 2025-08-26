import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class MoMoConfig {
  // MoMo Test Environment - Thay đổi thành production khi deploy
  static const String partnerCode = 'MOMO'; // Sandbox partner code
  static const String accessKey = 'F8BBA842ECF85'; // Sandbox access key
  static const String secretKey =
      'K951B6PE1waDMi640xX08PD3vg6EkVlz'; // Sandbox secret key
  static const String endpoint =
      'https://test-payment.momo.vn/v2/gateway/api/create';
  static const String ipnUrl =
      'https://your-domain.com/momo/callback'; // Webhook URL
  static const String redirectUrl =
      'https://your-domain.com/momo/return'; // Return URL
  static const String requestType = 'payWithATM'; // Payment type
}

class MoMoPaymentRequest {
  final String partnerCode;
  final String requestId;
  final double amount;
  final String orderId;
  final String orderInfo;
  final String redirectUrl;
  final String ipnUrl;
  final String requestType;
  final String signature;
  final String extraData;
  final String lang;

  MoMoPaymentRequest({
    required this.partnerCode,
    required this.requestId,
    required this.amount,
    required this.orderId,
    required this.orderInfo,
    required this.redirectUrl,
    required this.ipnUrl,
    required this.requestType,
    required this.signature,
    this.extraData = '',
    this.lang = 'vi',
  });

  Map<String, dynamic> toJson() {
    return {
      'partnerCode': partnerCode,
      'requestId': requestId,
      'amount': amount.toInt(),
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
  final double amount;
  final String message;
  final String resultCode;
  final String payUrl;
  final String deeplink;
  final String qrCodeUrl;

  MoMoPaymentResponse({
    required this.partnerCode,
    required this.requestId,
    required this.orderId,
    required this.amount,
    required this.message,
    required this.resultCode,
    required this.payUrl,
    required this.deeplink,
    required this.qrCodeUrl,
  });

  factory MoMoPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MoMoPaymentResponse(
      partnerCode: json['partnerCode'] ?? '',
      requestId: json['requestId'] ?? '',
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      message: json['message'] ?? '',
      resultCode: json['resultCode'] ?? '',
      payUrl: json['payUrl'] ?? '',
      deeplink: json['deeplink'] ?? '',
      qrCodeUrl: json['qrCodeUrl'] ?? '',
    );
  }

  bool get isSuccess => resultCode == '0';
}

class MoMoService {
  final Dio _dio = Dio();

  // Create MoMo payment request
  Future<MoMoPaymentResponse?> createPayment({
    required String orderId,
    required double amount,
    required String orderInfo,
  }) async {
    try {
      final requestId = _generateRequestId();

      // Create raw signature string
      final rawSignature =
          'accessKey=${MoMoConfig.accessKey}'
          '&amount=${amount.toInt()}'
          '&extraData='
          '&ipnUrl=${MoMoConfig.ipnUrl}'
          '&orderId=$orderId'
          '&orderInfo=$orderInfo'
          '&partnerCode=${MoMoConfig.partnerCode}'
          '&redirectUrl=${MoMoConfig.redirectUrl}'
          '&requestId=$requestId'
          '&requestType=${MoMoConfig.requestType}';

      // Generate HMAC SHA256 signature
      final signature = _generateSignature(rawSignature);

      final request = MoMoPaymentRequest(
        partnerCode: MoMoConfig.partnerCode,
        requestId: requestId,
        amount: amount,
        orderId: orderId,
        orderInfo: orderInfo,
        redirectUrl: MoMoConfig.redirectUrl,
        ipnUrl: MoMoConfig.ipnUrl,
        requestType: MoMoConfig.requestType,
        signature: signature,
      );

      print('MoMo Request: ${request.toJson()}');

      final response = await _dio.post(
        MoMoConfig.endpoint,
        data: request.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) =>
              status! < 500, // Accept all responses < 500
        ),
      );

      print('MoMo Response: ${response.data}');

      if (response.statusCode == 200) {
        return MoMoPaymentResponse.fromJson(response.data);
      } else {
        print('MoMo API Error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('MoMo Service Error: $e');
      return null;
    }
  }

  // Generate request ID
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'MM$timestamp$random';
  }

  // Generate HMAC SHA256 signature
  String _generateSignature(String rawSignature) {
    final key = utf8.encode(MoMoConfig.secretKey);
    final message = utf8.encode(rawSignature);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);
    return digest.toString();
  }

  // Verify signature from callback
  bool verifySignature(Map<String, dynamic> callbackData) {
    try {
      final receivedSignature = callbackData['signature'] ?? '';

      final rawSignature =
          'accessKey=${MoMoConfig.accessKey}'
          '&amount=${callbackData['amount']}'
          '&extraData=${callbackData['extraData'] ?? ''}'
          '&message=${callbackData['message']}'
          '&orderId=${callbackData['orderId']}'
          '&orderInfo=${callbackData['orderInfo']}'
          '&orderType=${callbackData['orderType']}'
          '&partnerCode=${callbackData['partnerCode']}'
          '&payType=${callbackData['payType']}'
          '&requestId=${callbackData['requestId']}'
          '&responseTime=${callbackData['responseTime']}'
          '&resultCode=${callbackData['resultCode']}'
          '&transId=${callbackData['transId']}';

      final expectedSignature = _generateSignature(rawSignature);
      return expectedSignature == receivedSignature;
    } catch (e) {
      print('Signature verification error: $e');
      return false;
    }
  }
}

// MoMo callback/IPN response model
class MoMoCallback {
  final String partnerCode;
  final String requestId;
  final String orderId;
  final double amount;
  final String orderInfo;
  final String orderType;
  final String transId;
  final String resultCode;
  final String message;
  final String payType;
  final String responseTime;
  final String extraData;
  final String signature;

  MoMoCallback({
    required this.partnerCode,
    required this.requestId,
    required this.orderId,
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
      requestId: json['requestId'] ?? '',
      orderId: json['orderId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      orderInfo: json['orderInfo'] ?? '',
      orderType: json['orderType'] ?? '',
      transId: json['transId'] ?? '',
      resultCode: json['resultCode'] ?? '',
      message: json['message'] ?? '',
      payType: json['payType'] ?? '',
      responseTime: json['responseTime'] ?? '',
      extraData: json['extraData'] ?? '',
      signature: json['signature'] ?? '',
    );
  }

  bool get isSuccess => resultCode == '0';
}
