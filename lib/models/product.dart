class Product {
  final String productId;
  final String productName;
  final double taxRate;

  Product({
    required this.productId,
    required this.productName,
    required this.taxRate,
  });

  // Convert Product object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'Product_ID': productId,
      'Product_Name': productName,
      'Tax_Rate': taxRate,
    };
  }

  // Create Product object from Map (database result)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['Product_ID'] ?? '',
      productName: map['Product_Name'] ?? '',
      taxRate: (map['Tax_Rate'] ?? 0.0).toDouble(),
    );
  }

  // Create a copy of Product with updated fields
  Product copyWith({String? productId, String? productName, double? taxRate}) {
    return Product(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  @override
  String toString() {
    return 'Product{productId: $productId, productName: $productName, taxRate: $taxRate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.productId == productId;
  }

  @override
  int get hashCode {
    return productId.hashCode;
  }
}
