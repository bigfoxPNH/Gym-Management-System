import 'package:gympro/models/product.dart';

class CartItem {
  final String id;
  final String userId;
  final String productId;
  final Product? product; // Product details
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.addedAt,
  });

  double get totalPrice {
    if (product == null) return 0;
    return product!.finalPrice * quantity;
  }

  factory CartItem.fromMap(Map<String, dynamic> map, String id) {
    return CartItem(
      id: id,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      product: map['product'] != null
          ? Product.fromMap(map['product'], map['productId'])
          : null,
      quantity: map['quantity'] ?? 1,
      addedAt: _parseTimestamp(map['addedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'addedAt': addedAt,
    };
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (timestamp is String) return DateTime.parse(timestamp);
    try {
      return (timestamp as dynamic).toDate();
    } catch (e) {
      return DateTime.now();
    }
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    Product? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
