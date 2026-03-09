import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'membership_card.dart';

enum PurchaseStatus {
  pending('Đang xử lý'),
  active('Đang hoạt động'),
  expired('Đã hết hạn'),
  cancelled('Đã hủy');

  const PurchaseStatus(this.label);
  final String label;
}

class MembershipPurchase {
  final String id;
  final String userId; // ID người mua
  final String cardId; // ID template thẻ tập
  final String cardName; // Tên thẻ tập (copy từ template)
  final String description; // Mô tả (copy từ template)
  final CardType cardType; // Loại thẻ (copy từ template)
  final DurationType durationType; // Loại thời gian (copy từ template)
  final int duration; // Số lượng thời gian (copy từ template)
  final DateTime? customEndDate; // Ngày kết thúc tùy chỉnh (copy từ template)
  final double price; // Giá đã thanh toán
  final DateTime purchaseDate; // Ngày mua
  final DateTime startDate; // Ngày bắt đầu (thường = purchaseDate)
  final DateTime endDate; // Ngày kết thúc (tính từ startDate + duration)
  final PurchaseStatus status; // Trạng thái
  final DateTime createdAt;
  final DateTime updatedAt;

  const MembershipPurchase({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.cardName,
    required this.description,
    required this.cardType,
    required this.durationType,
    required this.duration,
    this.customEndDate,
    required this.price,
    required this.purchaseDate,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from MembershipCard template
  factory MembershipPurchase.fromTemplate({
    required String id,
    required String userId,
    required MembershipCard template,
    DateTime? purchaseDate,
    DateTime? startDate,
    PurchaseStatus? status,
  }) {
    final purchase = purchaseDate ?? DateTime.now();
    final start = startDate ?? purchase;
    final end = MembershipCard.calculateEndDate(
      start,
      template.durationType,
      template.duration,
      template.customEndDate,
    );

    // Validate template has valid ID
    if (template.id.isEmpty) {
      throw ArgumentError('Template must have a valid ID');
    }

    return MembershipPurchase(
      id: id,
      userId: userId,
      cardId: template.id,
      cardName: template.cardName,
      description: template.description,
      cardType: template.cardType,
      durationType: template.durationType,
      duration: template.duration,
      customEndDate: template.customEndDate,
      price: template.price,
      purchaseDate: purchase,
      startDate: start,
      endDate: end,
      status:
          status ??
          PurchaseStatus.pending, // Default to pending instead of active
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cardId': cardId,
      'cardName': cardName,
      'description': description,
      'cardType': cardType.name,
      'durationType': durationType.name,
      'duration': duration,
      'customEndDate': customEndDate?.millisecondsSinceEpoch,
      'price': price,
      'purchaseDate': purchaseDate.millisecondsSinceEpoch,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from Firestore document
  factory MembershipPurchase.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return MembershipPurchase(
      id: documentId,
      userId: map['userId'] ?? '',
      cardId: map['cardId'] ?? '',
      cardName: map['cardName'] ?? '',
      description: map['description'] ?? '',
      cardType: CardType.values.firstWhere(
        (type) => type.name == map['cardType'],
        orElse: () => CardType.member,
      ),
      durationType: DurationType.values.firstWhere(
        (type) => type.name == map['durationType'],
        orElse: () => DurationType.months,
      ),
      duration: map['duration']?.toInt() ?? 0,
      customEndDate: map['customEndDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['customEndDate'])
          : null,
      price: (map['price'] ?? 0).toDouble(),
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(map['purchaseDate']),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      status: PurchaseStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => PurchaseStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory MembershipPurchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipPurchase.fromMap(data, doc.id);
  }

  // Copy with method for updates
  MembershipPurchase copyWith({
    String? id,
    String? userId,
    String? cardId,
    String? cardName,
    String? description,
    CardType? cardType,
    DurationType? durationType,
    int? duration,
    DateTime? customEndDate,
    double? price,
    DateTime? purchaseDate,
    DateTime? startDate,
    DateTime? endDate,
    PurchaseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipPurchase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      cardName: cardName ?? this.cardName,
      description: description ?? this.description,
      cardType: cardType ?? this.cardType,
      durationType: durationType ?? this.durationType,
      duration: duration ?? this.duration,
      customEndDate: customEndDate ?? this.customEndDate,
      price: price ?? this.price,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final daysDiff = endDate.difference(now).inDays;
    return daysDiff >= 0 && daysDiff <= 7;
  }

  int get remainingDays {
    final now = DateTime.now();
    final diff = endDate.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  String get statusText {
    if (isExpired && status == PurchaseStatus.active) {
      return 'Đã hết hạn';
    }
    return status.label;
  }

  String get formattedPrice {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')} VND';
  }

  String get formattedDuration {
    switch (durationType) {
      case DurationType.days:
        return '$duration ${durationType.label}';
      case DurationType.months:
        return '$duration ${durationType.label}';
      case DurationType.years:
        return '$duration ${durationType.label}';
      case DurationType.custom:
        if (customEndDate != null) {
          return 'Đến ${DateFormat('dd/MM/yyyy').format(customEndDate!)}';
        }
        return 'Tùy chỉnh';
    }
  }
}
