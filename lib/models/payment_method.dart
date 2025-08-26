enum PaymentMethodType {
  momo,
  banking,
  cash, // For demo purposes
}

class PaymentMethod {
  final String id;
  final String name;
  final String displayName;
  final PaymentMethodType type;
  final String iconUrl;
  final bool isEnabled;
  final String description;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.displayName,
    required this.type,
    required this.iconUrl,
    required this.isEnabled,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'type': type.toString(),
      'iconUrl': iconUrl,
      'isEnabled': isEnabled,
      'description': description,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      displayName: map['displayName'] ?? '',
      type: PaymentMethodType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => PaymentMethodType.cash,
      ),
      iconUrl: map['iconUrl'] ?? '',
      isEnabled: map['isEnabled'] ?? false,
      description: map['description'] ?? '',
    );
  }

  // Static methods to create default payment methods
  static List<PaymentMethod> getDefaultMethods() {
    return [
      PaymentMethod(
        id: 'momo',
        name: 'momo',
        displayName: 'Ví điện tử MoMo',
        type: PaymentMethodType.momo,
        iconUrl: 'assets/images/momo_logo.png',
        isEnabled: true,
        description: 'Thanh toán qua ví điện tử MoMo',
      ),
      PaymentMethod(
        id: 'banking',
        name: 'banking',
        displayName: 'Chuyển khoản ngân hàng',
        type: PaymentMethodType.banking,
        iconUrl: 'assets/images/bank_logo.png',
        isEnabled: true,
        description: 'Chuyển khoản qua Internet Banking',
      ),
      PaymentMethod(
        id: 'cash',
        name: 'cash',
        displayName: 'Thanh toán tại quầy',
        type: PaymentMethodType.cash,
        iconUrl: 'assets/images/cash_logo.png',
        isEnabled: true,
        description: 'Thanh toán trực tiếp tại gym',
      ),
    ];
  }
}
