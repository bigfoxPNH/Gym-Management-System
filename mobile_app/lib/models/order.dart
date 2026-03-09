import 'package:gympro/models/product.dart';

enum OrderStatus {
  pending('pending', 'Chờ xác nhận', 'Đơn hàng đang chờ xác nhận'),
  confirmed('confirmed', 'Đã xác nhận', 'Đơn hàng đã được xác nhận'),
  preparing('preparing', 'Đang chuẩn bị', 'Đang chuẩn bị hàng'),
  shipping('shipping', 'Đang giao', 'Đơn hàng đang được giao'),
  delivered('delivered', 'Đã giao', 'Đơn hàng đã được giao thành công'),
  cancelled('cancelled', 'Đã hủy', 'Đơn hàng đã bị hủy'),
  returned('returned', 'Đã trả hàng', 'Đơn hàng đã được trả lại');

  final String value;
  final String displayName;
  final String description;

  const OrderStatus(this.value, this.displayName, this.description);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

enum PaymentMethod {
  cod('cod', 'Thanh toán khi nhận hàng (COD)'),
  bankTransfer('bank_transfer', 'Chuyển khoản ngân hàng'),
  momo('momo', 'Ví MoMo'),
  zalopay('zalopay', 'ZaloPay');

  final String value;
  final String displayName;

  const PaymentMethod(this.value, this.displayName);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cod,
    );
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double discount;

  OrderItem({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    this.discount = 0,
  });

  double get subtotal => price * quantity;
  double get totalDiscount => (price * discount / 100) * quantity;
  double get total => subtotal - totalDiscount;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      discount: (map['discount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'discount': discount,
    };
  }

  factory OrderItem.fromProduct(Product product, int quantity) {
    return OrderItem(
      productId: product.id,
      productName: product.name,
      productImage: product.images.isNotEmpty ? product.images.first : null,
      price: product.price,
      quantity: quantity,
      discount: product.discount,
    );
  }
}

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final bool isPaid;

  // Shipping info
  final String recipientName;
  final String phoneNumber;
  final String address;
  final String ward;
  final String district;
  final String city;

  // Price info
  final double subtotal;
  final double shippingFee;
  final double discount;
  final double total;

  // Notes
  final String? note;
  final String? cancelReason;

  // Timestamps
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.status,
    required this.paymentMethod,
    this.isPaid = false,
    required this.recipientName,
    required this.phoneNumber,
    required this.address,
    required this.ward,
    required this.district,
    required this.city,
    required this.subtotal,
    required this.shippingFee,
    this.discount = 0,
    required this.total,
    this.note,
    this.cancelReason,
    required this.createdAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  String get fullAddress {
    return '$address, $ward, $district, $city';
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      status: OrderStatus.fromString(map['status'] ?? 'pending'),
      paymentMethod: PaymentMethod.fromString(map['paymentMethod'] ?? 'cod'),
      isPaid: map['isPaid'] ?? false,
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      ward: map['ward'] ?? '',
      district: map['district'] ?? '',
      city: map['city'] ?? '',
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      shippingFee: (map['shippingFee'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      note: map['note'],
      cancelReason: map['cancelReason'],
      createdAt: _parseTimestamp(map['createdAt']) ?? DateTime.now(),
      confirmedAt: _parseTimestamp(map['confirmedAt']),
      shippedAt: _parseTimestamp(map['shippedAt']),
      deliveredAt: _parseTimestamp(map['deliveredAt']),
      cancelledAt: _parseTimestamp(map['cancelledAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'status': status.value,
      'paymentMethod': paymentMethod.value,
      'isPaid': isPaid,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'address': address,
      'ward': ward,
      'district': district,
      'city': city,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'note': note,
      'cancelReason': cancelReason,
      'createdAt': createdAt,
      'confirmedAt': confirmedAt,
      'shippedAt': shippedAt,
      'deliveredAt': deliveredAt,
      'cancelledAt': cancelledAt,
    };
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    try {
      return (timestamp as dynamic).toDate();
    } catch (e) {
      return null;
    }
  }
}
