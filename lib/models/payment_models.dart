// MoMo Payment Models

class PaymentResponse {
  final String partnerCode;
  final String orderId;
  final String requestId;
  final int amount;
  final String orderInfo;
  final String orderType;
  final int transId;
  final int resultCode;
  final String message;
  final String payUrl;
  final String? deeplink;
  final String? qrCodeUrl;
  final String? applink;
  final String? deeplinkMiniApp;

  PaymentResponse({
    required this.partnerCode,
    required this.orderId,
    required this.requestId,
    required this.amount,
    required this.orderInfo,
    required this.orderType,
    required this.transId,
    required this.resultCode,
    required this.message,
    required this.payUrl,
    this.deeplink,
    this.qrCodeUrl,
    this.applink,
    this.deeplinkMiniApp,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      partnerCode: json['partnerCode'] ?? '',
      orderId: json['orderId'] ?? '',
      requestId: json['requestId'] ?? '',
      amount: json['amount'] ?? 0,
      orderInfo: json['orderInfo'] ?? '',
      orderType: json['orderType'] ?? '',
      transId: json['transId'] ?? 0,
      resultCode: json['resultCode'] ?? -1,
      message: json['message'] ?? '',
      payUrl: json['payUrl'] ?? '',
      deeplink: json['deeplink'],
      qrCodeUrl: json['qrCodeUrl'],
      applink: json['applink'],
      deeplinkMiniApp: json['deeplinkMiniApp'],
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
      'payUrl': payUrl,
      'deeplink': deeplink,
      'qrCodeUrl': qrCodeUrl,
      'applink': applink,
      'deeplinkMiniApp': deeplinkMiniApp,
    };
  }

  bool get isSuccess => resultCode == 0;
}

class PaymentQueryResponse {
  final String partnerCode;
  final String orderId;
  final String requestId;
  final int amount;
  final String orderInfo;
  final String orderType;
  final int transId;
  final int resultCode;
  final String message;
  final String payType;
  final int responseTime;
  final String extraData;

  PaymentQueryResponse({
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
  });

  factory PaymentQueryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentQueryResponse(
      partnerCode: json['partnerCode'] ?? '',
      orderId: json['orderId'] ?? '',
      requestId: json['requestId'] ?? '',
      amount: json['amount'] ?? 0,
      orderInfo: json['orderInfo'] ?? '',
      orderType: json['orderType'] ?? '',
      transId: json['transId'] ?? 0,
      resultCode: json['resultCode'] ?? -1,
      message: json['message'] ?? '',
      payType: json['payType'] ?? '',
      responseTime: json['responseTime'] ?? 0,
      extraData: json['extraData'] ?? '',
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
    };
  }

  bool get isSuccess => resultCode == 0;
  bool get isPending => resultCode == 1000;
  bool get isFailed => resultCode != 0 && resultCode != 1000;
}

class PaymentCallbackData {
  final String partnerCode;
  final String orderId;
  final String requestId;
  final int amount;
  final String orderInfo;
  final String orderType;
  final int transId;
  final int resultCode;
  final String message;
  final String payType;
  final int responseTime;
  final String extraData;
  final String signature;

  PaymentCallbackData({
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

  factory PaymentCallbackData.fromJson(Map<String, dynamic> json) {
    return PaymentCallbackData(
      partnerCode: json['partnerCode'] ?? '',
      orderId: json['orderId'] ?? '',
      requestId: json['requestId'] ?? '',
      amount: json['amount'] ?? 0,
      orderInfo: json['orderInfo'] ?? '',
      orderType: json['orderType'] ?? '',
      transId: json['transId'] ?? 0,
      resultCode: json['resultCode'] ?? -1,
      message: json['message'] ?? '',
      payType: json['payType'] ?? '',
      responseTime: json['responseTime'] ?? 0,
      extraData: json['extraData'] ?? '',
      signature: json['signature'] ?? '',
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

  bool get isSuccess => resultCode == 0;
  bool get isPending => resultCode == 1000;
  bool get isFailed => resultCode != 0 && resultCode != 1000;
}

// Banking QR Models
class BankingQRResponse {
  final String qrCode;
  final String qrDataURL;
  final bool success;
  final String? message;

  BankingQRResponse({
    required this.qrCode,
    required this.qrDataURL,
    required this.success,
    this.message,
  });

  factory BankingQRResponse.fromJson(Map<String, dynamic> json) {
    return BankingQRResponse(
      qrCode: json['qrCode'] ?? json['data']?['qrCode'] ?? '',
      qrDataURL: json['qrDataURL'] ?? json['data']?['qrDataURL'] ?? '',
      success: json['success'] ?? json['code'] == '00',
      message: json['message'] ?? json['desc'],
    );
  }
}

// Payment Status Enum
enum PaymentStatus { pending, success, failed, cancelled, expired }

extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Đang xử lý';
      case PaymentStatus.success:
        return 'Thành công';
      case PaymentStatus.failed:
        return 'Thất bại';
      case PaymentStatus.cancelled:
        return 'Đã hủy';
      case PaymentStatus.expired:
        return 'Hết hạn';
    }
  }

  String get color {
    switch (this) {
      case PaymentStatus.pending:
        return 'orange';
      case PaymentStatus.success:
        return 'green';
      case PaymentStatus.failed:
        return 'red';
      case PaymentStatus.cancelled:
        return 'grey';
      case PaymentStatus.expired:
        return 'red';
    }
  }
}

// Payment Method Enum
enum PaymentMethod { momo, banking, cash }

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.banking:
        return 'Chuyển khoản ngân hàng';
      case PaymentMethod.cash:
        return 'Tiền mặt';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.momo:
        return '💳';
      case PaymentMethod.banking:
        return '🏦';
      case PaymentMethod.cash:
        return '💰';
    }
  }
}
