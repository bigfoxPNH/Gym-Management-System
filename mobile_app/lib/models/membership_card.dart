import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum CardType {
  member('Thẻ hội viên'),
  premium('Thẻ Premium'),
  vip('Thẻ VIP');

  const CardType(this.label);
  final String label;
}

enum DurationType {
  days('Ngày'),
  months('Tháng'),
  years('Năm'),
  custom('Tùy chỉnh');

  const DurationType(this.label);
  final String label;
}

class MembershipCard {
  final String id;
  final String cardName; // Tên thẻ tập
  final String description; // Mô tả thẻ tập
  final CardType cardType; // Loại thẻ
  final DurationType durationType; // Loại thời gian
  final int duration; // Số lượng thời gian (dùng cho ngày/tháng/năm)
  final DateTime? customEndDate; // Ngày kết thúc cụ thể (dùng cho tùy chỉnh)
  final double price; // Giá tiền (VND)
  // Note: Không lưu endDate trong template, sẽ tính khi user mua
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final bool isActive; // Trạng thái hoạt động

  const MembershipCard({
    required this.id,
    required this.cardName,
    required this.description,
    required this.cardType,
    required this.durationType,
    required this.duration,
    this.customEndDate,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.isActive = true,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cardName': cardName,
      'description': description,
      'cardType': cardType.name,
      'durationType': durationType.name,
      'duration': duration,
      'customEndDate': customEndDate?.millisecondsSinceEpoch,
      'price': price,
      // Note: endDate không lưu trong template, sẽ tính khi user mua
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  // Create from Firestore document
  factory MembershipCard.fromMap(Map<String, dynamic> map, String documentId) {
    return MembershipCard(
      id: documentId,
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
      // Note: endDate không có trong template, sẽ tính khi cần
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory MembershipCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MembershipCard.fromMap(data, doc.id);
  }

  // Copy with method for updates
  MembershipCard copyWith({
    String? id,
    String? cardName,
    String? description,
    CardType? cardType,
    DurationType? durationType,
    int? duration,
    DateTime? customEndDate,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isActive,
  }) {
    return MembershipCard(
      id: id ?? this.id,
      cardName: cardName ?? this.cardName,
      description: description ?? this.description,
      cardType: cardType ?? this.cardType,
      durationType: durationType ?? this.durationType,
      duration: duration ?? this.duration,
      customEndDate: customEndDate ?? this.customEndDate,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper method to calculate end date from start date and duration
  static DateTime calculateEndDate(
    DateTime startDate,
    DurationType durationType,
    int duration,
    DateTime? customEndDate,
  ) {
    // Validate duration to prevent overflow
    if (duration <= 0 || duration > 99999) {
      duration = 1; // Default to 1 if invalid
    }

    try {
      switch (durationType) {
        case DurationType.days:
          // Limit days to prevent overflow (max ~270 years)
          final safeDays = duration > 100000 ? 100000 : duration;
          return startDate.add(Duration(days: safeDays));
        case DurationType.months:
          // Limit months to prevent overflow and handle month boundaries correctly
          final safeMonths = duration > 1200 ? 1200 : duration; // Max 100 years
          DateTime result = DateTime(
            startDate.year,
            startDate.month + safeMonths,
            startDate.day,
          );

          // Handle case where the target day doesn't exist in the target month
          // (e.g., Jan 31 + 1 month should be Feb 28/29, not Mar 3)
          if (result.day != startDate.day) {
            // Go to the last day of the target month
            result = DateTime(result.year, result.month + 1, 0);
          }
          return result;
        case DurationType.years:
          // Limit years to prevent overflow and handle leap years
          final safeYears = duration > 100 ? 100 : duration; // Max 100 years
          DateTime result = DateTime(
            startDate.year + safeYears,
            startDate.month,
            startDate.day,
          );

          // Handle leap year case (Feb 29 -> Feb 28 in non-leap year)
          if (startDate.month == 2 && startDate.day == 29) {
            final targetYear = startDate.year + safeYears;
            if (!_isLeapYear(targetYear)) {
              result = DateTime(targetYear, 2, 28);
            }
          }
          return result;
        case DurationType.custom:
          return customEndDate ?? startDate.add(const Duration(days: 30));
      }
    } catch (e) {
      // If any error occurs, return a safe default (1 month from start)
      return DateTime(startDate.year, startDate.month + 1, startDate.day);
    }
  }

  // Helper method to check if a year is a leap year
  static bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  // Helper method to get formatted duration
  String getFormattedDuration() {
    switch (durationType) {
      case DurationType.days:
        return '$duration ${durationType.label}';
      case DurationType.months:
        return '$duration ${durationType.label}';
      case DurationType.years:
        return '$duration ${durationType.label}';
      case DurationType.custom:
        if (customEndDate != null) {
          return 'Đến ${customEndDate!.day}/${customEndDate!.month}/${customEndDate!.year}';
        }
        return 'Tùy chỉnh';
    }
  }

  // Calculate end date when user purchases (based on purchase date)
  DateTime calculateEndDateFromPurchase([DateTime? purchaseDate]) {
    final startDate = purchaseDate ?? DateTime.now();
    return calculateEndDate(startDate, durationType, duration, customEndDate);
  }

  // Check if membership would be expired (need purchase date)
  bool isExpiredOn(DateTime purchaseDate) {
    final endDate = calculateEndDateFromPurchase(purchaseDate);
    return DateTime.now().isAfter(endDate);
  }

  // Check if membership would be expiring soon (need purchase date)
  bool isExpiringSoonOn(DateTime purchaseDate) {
    final endDate = calculateEndDateFromPurchase(purchaseDate);
    final now = DateTime.now();
    final daysDiff = endDate.difference(now).inDays;
    return daysDiff >= 0 && daysDiff <= 7;
  }

  // Get remaining days until expiration (need purchase date)
  int getRemainingDaysFrom(DateTime purchaseDate) {
    final endDate = calculateEndDateFromPurchase(purchaseDate);
    final now = DateTime.now();
    final diff = endDate.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  // Get status color based on expiration (need purchase date)
  Color getStatusColorFrom(DateTime purchaseDate) {
    if (isExpiredOn(purchaseDate)) return Colors.red;
    if (isExpiringSoonOn(purchaseDate)) return Colors.orange;
    return Colors.green;
  }

  // Get status text (need purchase date)
  String getStatusTextFrom(DateTime purchaseDate) {
    if (isExpiredOn(purchaseDate)) return 'Đã hết hạn';
    if (isExpiringSoonOn(purchaseDate)) return 'Sắp hết hạn';
    return 'Còn hiệu lực';
  }

  // Get preview info for template (what user will get if they buy now)
  String getPreviewInfo() {
    final now = DateTime.now();
    final endDate = calculateEndDateFromPurchase(now);
    final formatter = DateFormat('dd/MM/yyyy');
    return 'Nếu mua hôm nay (${formatter.format(now)}) sẽ hết hạn: ${formatter.format(endDate)}';
  }

  // Helper method to get formatted price
  String getFormattedPrice() {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VND';
  }

  String get cardNumber => id;
  DateTime get startDate => createdAt;
  DateTime get endDate =>
      customEndDate ?? createdAt.add(Duration(days: duration));

  @override
  String toString() {
    return 'MembershipCard(id: $id, cardName: $cardName, cardType: ${cardType.label}, price: ${getFormattedPrice()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MembershipCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
