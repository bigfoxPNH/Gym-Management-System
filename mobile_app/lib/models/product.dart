class Product {
  final String id;
  final String name;
  final String category; // Whey Protein, Mass, Creatine, etc.
  final String manufacturer;
  final double originalPrice;
  final double sellingPrice;
  final int stockQuantity;
  final String description;
  final List<String> images;
  final ProductStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Static getter for product categories
  static List<String> get productCategories => ProductCategory.all;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.manufacturer,
    required this.originalPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.description,
    required this.images,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      originalPrice: (json['originalPrice'] ?? 0).toDouble(),
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      stockQuantity: json['stockQuantity'] ?? 0,
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      status: ProductStatus.fromString(json['status'] ?? 'in_stock'),
      createdAt: json['createdAt'] != null
          ? _parseTimestamp(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? _parseTimestamp(json['updatedAt'])
          : DateTime.now(),
    );
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      stockQuantity: map['stockQuantity'] ?? 0,
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      status: ProductStatus.fromString(map['status'] ?? 'in_stock'),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    // Handle Firestore Timestamp
    if (timestamp.runtimeType.toString() == 'Timestamp') {
      return timestamp.toDate();
    }

    // Handle DateTime
    if (timestamp is DateTime) {
      return timestamp;
    }

    // Handle String (ISO 8601)
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle milliseconds since epoch
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'manufacturer': manufacturer,
      'originalPrice': originalPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'description': description,
      'images': images,
      'status': status.value,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? category,
    String? manufacturer,
    double? originalPrice,
    double? sellingPrice,
    int? stockQuantity,
    String? description,
    List<String>? images,
    ProductStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      originalPrice: originalPrice ?? this.originalPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      description: description ?? this.description,
      images: images ?? this.images,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - sellingPrice) / originalPrice * 100);
  }

  bool get isLowStock => stockQuantity <= 10;

  // Price for user shopping (using sellingPrice)
  double get price => sellingPrice;

  // Discount amount
  double get discount => discountPercentage;

  // Final price after discount
  double get finalPrice => sellingPrice;
}

enum ProductStatus {
  inStock('in_stock', 'Còn hàng'),
  outOfStock('out_of_stock', 'Hết hàng'),
  lowStock('low_stock', 'Sắp hết');

  final String value;
  final String displayName;

  const ProductStatus(this.value, this.displayName);

  static ProductStatus fromString(String value) {
    switch (value) {
      case 'in_stock':
        return ProductStatus.inStock;
      case 'out_of_stock':
        return ProductStatus.outOfStock;
      case 'low_stock':
        return ProductStatus.lowStock;
      default:
        return ProductStatus.inStock;
    }
  }
}

class ProductCategory {
  static const String wheyProtein = 'Whey Protein';
  static const String mass = 'Mass';
  static const String casein = 'Casein';
  static const String eaas = 'EAAs';
  static const String bcaas = 'BCAAs';
  static const String creatine = 'Creatine';
  static const String preWorkout = 'Pre-workout';
  static const String vitaminMineral = 'Vitamin - Khoáng chất';
  static const String food = 'Đồ ăn liền';
  static const String equipment = 'Dụng cụ tập';
  static const String other = 'Khác';

  static List<String> get all => [
    wheyProtein,
    mass,
    casein,
    eaas,
    bcaas,
    creatine,
    preWorkout,
    vitaminMineral,
    food,
    equipment,
    other,
  ];
}
