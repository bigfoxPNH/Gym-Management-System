import 'payment_method.dart';

enum PaymentStatus {
  pending, // Chờ thanh toán
  processing, // Đang xử lý
  completed, // Thành công
  failed, // Thất bại
  cancelled, // Đã hủy
  expired, // Hết hạn
}

enum PaymentType { membership, service, product }

class PaymentTransaction {
  final String id;
  final String userId;
  final String membershipCardId;
  final String membershipPurchaseId;
  final PaymentType paymentType;
  final PaymentMethodType paymentMethod;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String? transactionId; // ID từ payment gateway
  final String? qrCodeUrl; // QR code để thanh toán
  final String? bankInfo; // Thông tin chuyển khoản
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiredAt;
  final Map<String, dynamic>? metadata; // Thông tin bổ sung

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.membershipCardId,
    required this.membershipPurchaseId,
    required this.paymentType,
    required this.paymentMethod,
    required this.amount,
    this.currency = 'VND',
    required this.status,
    this.transactionId,
    this.qrCodeUrl,
    this.bankInfo,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.expiredAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'membershipCardId': membershipCardId,
      'membershipPurchaseId': membershipPurchaseId,
      'paymentType': paymentType.toString(),
      'paymentMethod': paymentMethod.toString(),
      'amount': amount,
      'currency': currency,
      'status': status.toString(),
      'transactionId': transactionId,
      'qrCodeUrl': qrCodeUrl,
      'bankInfo': bankInfo,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'expiredAt': expiredAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      membershipCardId: map['membershipCardId'] ?? '',
      membershipPurchaseId: map['membershipPurchaseId'] ?? '',
      paymentType: PaymentType.values.firstWhere(
        (e) => e.toString() == map['paymentType'],
        orElse: () => PaymentType.membership,
      ),
      paymentMethod: PaymentMethodType.values.firstWhere(
        (e) => e.toString() == map['paymentMethod'],
        orElse: () => PaymentMethodType.cash,
      ),
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'VND',
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: map['transactionId'],
      qrCodeUrl: map['qrCodeUrl'],
      bankInfo: map['bankInfo'],
      description: map['description'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      expiredAt: map['expiredAt'] != null
          ? DateTime.parse(map['expiredAt'])
          : null,
      metadata: map['metadata'],
    );
  }

  PaymentTransaction copyWith({
    String? id,
    String? userId,
    String? membershipCardId,
    String? membershipPurchaseId,
    PaymentType? paymentType,
    PaymentMethodType? paymentMethod,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? transactionId,
    String? qrCodeUrl,
    String? bankInfo,
    String? description,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? expiredAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      membershipCardId: membershipCardId ?? this.membershipCardId,
      membershipPurchaseId: membershipPurchaseId ?? this.membershipPurchaseId,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      bankInfo: bankInfo ?? this.bankInfo,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      expiredAt: expiredAt ?? this.expiredAt,
      metadata: metadata ?? this.metadata,
    );
  }

  String getStatusText() {
    switch (status) {
      case PaymentStatus.pending:
        return 'Chờ thanh toán';
      case PaymentStatus.processing:
        return 'Đang xử lý';
      case PaymentStatus.completed:
        return 'Thành công';
      case PaymentStatus.failed:
        return 'Thất bại';
      case PaymentStatus.cancelled:
        return 'Đã hủy';
      case PaymentStatus.expired:
        return 'Hết hạn';
    }
  }

  String getPaymentMethodText() {
    switch (paymentMethod) {
      case PaymentMethodType.momo:
        return 'Ví điện tử MoMo';
      case PaymentMethodType.banking:
        return 'Chuyển khoản ngân hàng';
      case PaymentMethodType.cash:
        return 'Thanh toán tại quầy';
    }
  }

  bool get isCompleted => status == PaymentStatus.completed;
  bool get isPending => status == PaymentStatus.pending;
  bool get isFailed =>
      status == PaymentStatus.failed || status == PaymentStatus.expired;
  bool get canCancel => status == PaymentStatus.pending;
}
