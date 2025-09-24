class PaymentMode {
  final String paymentModeId;
  final String paymentModeName;
  final String type; // cash, card, bank_transfer, upi, cheque, other
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMode({
    required this.paymentModeId,
    required this.paymentModeName,
    required this.type,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory PaymentMode.fromMap(Map<String, dynamic> map) {
    return PaymentMode(
      paymentModeId: map['payment_mode_id'] ?? '',
      paymentModeName: map['payment_mode_name'] ?? '',
      type: map['type'] ?? '',
      description: map['description'],
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'payment_mode_id': paymentModeId,
      'payment_mode_name': paymentModeName,
      'type': type,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  PaymentMode copyWith({
    String? paymentModeId,
    String? paymentModeName,
    String? type,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMode(
      paymentModeId: paymentModeId ?? this.paymentModeId,
      paymentModeName: paymentModeName ?? this.paymentModeName,
      type: type ?? this.type,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> get paymentTypes => [
    'cash',
    'card',
    'bank_transfer',
    'upi',
    'cheque',
    'other',
  ];

  static String getTypeDisplayName(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'upi':
        return 'UPI';
      case 'cheque':
        return 'Cheque';
      case 'other':
        return 'Other';
      default:
        return type;
    }
  }

  String get typeDisplayName => getTypeDisplayName(type);
}
