import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uni_links/uni_links.dart';

class MoMoConfig {
  // MoMo Test Environment - Thay đổi thành production khi deploy
  static const String partnerCode = 'YOUR_PARTNER_CODE';
  static const String accessKey = 'YOUR_ACCESS_KEY';
  static const String secretKey = 'YOUR_SECRET_KEY';
  static const String endpoint =
      'https://test-payment.momo.vn/v2/gateway/api/create'; // UAT
  static const String ipnUrl = 'https://webhook.site/xxxx'; // URL public
  static const String redirectUrl = 'https://momo.vn'; // URL public
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
  final String partnerCode = "MOMOXXXX2020";
  final String accessKey = "F8BBA842ECF85";
  final String secretKey = "K951B6PE1waDMi640xX08PD3vg6EkVlz";
  final String endpoint = "https://test-payment.momo.vn/v2/gateway/api/create";

  /// Creates a payment request to MoMo API.
  /// [amount] is the payment amount.
  /// [orderInfo] is the description of the order.
  Future<MoMoPaymentResponse> createPayment(
    double amount,
    String orderInfo,
  ) async {
    // Generate unique orderId and requestId based on timestamp
    final String orderId = DateTime.now().millisecondsSinceEpoch.toString();
    final String requestId = DateTime.now().millisecondsSinceEpoch.toString();

    // Prepare raw data for the request
    final Map<String, dynamic> rawData = {
      "partnerCode": partnerCode,
      "accessKey": accessKey,
      "requestId": requestId,
      "amount": amount.toString(),
      "orderId": orderId,
      "orderInfo": orderInfo,
      "redirectUrl": "https://momo.vn",
      "ipnUrl": "https://webhook.site/xxxx",
      "requestType": "captureWallet",
    };

    // Generate HMAC SHA256 signature
    final String rawSignature =
        "accessKey=$accessKey&amount=${rawData['amount']}&ipnUrl=${rawData['ipnUrl']}&orderId=${rawData['orderId']}&orderInfo=${rawData['orderInfo']}&partnerCode=$partnerCode&redirectUrl=${rawData['redirectUrl']}&requestId=$requestId&requestType=${rawData['requestType']}";
    final String signature = Hmac(
      sha256,
      utf8.encode(secretKey),
    ).convert(utf8.encode(rawSignature)).toString();

    // Add signature to the request data
    rawData['signature'] = signature;

    // Send POST request to MoMo API
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(rawData),
    );

    // Handle response
    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return MoMoPaymentResponse.fromJson(responseData);
    } else {
      throw Exception("Failed to create MoMo payment: ${response.body}");
    }
  }
}

void handleMoMoCallback() {
  uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      final result = uri.queryParameters['result'];
      if (result == 'success') {
        print('Payment successful');
      } else {
        print('Payment failed');
      }
    }
  });
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
