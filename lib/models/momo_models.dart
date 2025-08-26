import '../config/momo_config.dart';

class MoMoPaymentRequest {
  final String orderId;
  final int amount;
  final String orderInfo;
  final String requestType;
  final String extraData;
  final String lang;

  MoMoPaymentRequest({
    required this.orderId,
    required this.amount,
    required this.orderInfo,
    this.requestType = MoMoConfig.captureWallet,
    this.extraData = "",
    this.lang = "vi",
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'amount': amount,
      'orderInfo': orderInfo,
      'requestType': requestType,
      'extraData': extraData,
      'lang': lang,
    };
  }
}

class MoMoPaymentResponse {
  final String partnerCode;
  final String orderId;
  final String requestId;
  final int amount;
  final int responseTime;
  final String message;
  final int resultCode;
  final String? payUrl;
  final String? deeplink;
  final String? qrCodeUrl;
  final String? deeplinkMiniApp;

  MoMoPaymentResponse({
    required this.partnerCode,
    required this.orderId,
    required this.requestId,
    required this.amount,
    required this.responseTime,
    required this.message,
    required this.resultCode,
    this.payUrl,
    this.deeplink,
    this.qrCodeUrl,
    this.deeplinkMiniApp,
  });

  bool get isSuccess => resultCode == 0;

  factory MoMoPaymentResponse.fromJson(Map<String, dynamic> json) {
    return MoMoPaymentResponse(
      partnerCode: json['partnerCode'] ?? '',
      orderId: json['orderId'] ?? '',
      requestId: json['requestId'] ?? '',
      amount: json['amount'] ?? 0,
      responseTime: json['responseTime'] ?? 0,
      message: json['message'] ?? '',
      resultCode: json['resultCode'] ?? -1,
      payUrl: json['payUrl'],
      deeplink: json['deeplink'],
      qrCodeUrl: json['qrCodeUrl'],
      deeplinkMiniApp: json['deeplinkMiniApp'],
    );
  }
}

class MoMoCallbackResult {
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

  MoMoCallbackResult({
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

  bool get isSuccess => resultCode == 0;
  bool get isCancelled => resultCode == 1006;
  bool get isFailed => resultCode != 0 && resultCode != 1006;

  String get statusMessage {
    switch (resultCode) {
      case 0:
        return 'Thanh toán thành công';
      case 1006:
        return 'Người dùng hủy thanh toán';
      case 1001:
        return 'Giao dịch thất bại do lỗi từ MoMo';
      case 1002:
        return 'Giao dịch bị từ chối bởi nhà phát hành';
      case 1003:
        return 'Giao dịch bị hủy do quá thời gian thanh toán';
      case 1004:
        return 'Giao dịch thất bại do số dư không đủ';
      case 1005:
        return 'Giao dịch thất bại do URL hoặc QR code không hợp lệ';
      default:
        return 'Giao dịch thất bại: $message';
    }
  }

  factory MoMoCallbackResult.fromUri(Uri uri) {
    final params = uri.queryParameters;
    return MoMoCallbackResult(
      partnerCode: params['partnerCode'] ?? '',
      orderId: params['orderId'] ?? '',
      requestId: params['requestId'] ?? '',
      amount: int.tryParse(params['amount'] ?? '0') ?? 0,
      orderInfo: params['orderInfo'] ?? '',
      orderType: params['orderType'] ?? '',
      transId: params['transId'] ?? '',
      resultCode: int.tryParse(params['resultCode'] ?? '-1') ?? -1,
      message: params['message'] ?? '',
      payType: params['payType'] ?? '',
      responseTime: int.tryParse(params['responseTime'] ?? '0') ?? 0,
      extraData: params['extraData'] ?? '',
      signature: params['signature'] ?? '',
    );
  }

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
