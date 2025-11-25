class ShippingAddress {
  final String id;
  final String userId;
  final String recipientName;
  final String phoneNumber;
  final String address;
  final String ward; // Phường/Xã
  final String district; // Quận/Huyện
  final String city; // Tỉnh/Thành phố
  final bool isDefault;
  final DateTime createdAt;

  ShippingAddress({
    required this.id,
    required this.userId,
    required this.recipientName,
    required this.phoneNumber,
    required this.address,
    required this.ward,
    required this.district,
    required this.city,
    this.isDefault = false,
    required this.createdAt,
  });

  String get fullAddress {
    return '$address, $ward, $district, $city';
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map, String id) {
    return ShippingAddress(
      id: id,
      userId: map['userId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      ward: map['ward'] ?? '',
      district: map['district'] ?? '',
      city: map['city'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'address': address,
      'ward': ward,
      'district': district,
      'city': city,
      'isDefault': isDefault,
      'createdAt': createdAt,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    // Firestore Timestamp
    try {
      return (timestamp as dynamic).toDate();
    } catch (e) {
      return DateTime.now();
    }
  }

  ShippingAddress copyWith({
    String? id,
    String? userId,
    String? recipientName,
    String? phoneNumber,
    String? address,
    String? ward,
    String? district,
    String? city,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      ward: ward ?? this.ward,
      district: district ?? this.district,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
