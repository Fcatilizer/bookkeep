class CustomerEvent {
  final String eventNo;
  final String eventName;
  final String custId;
  final String productId;
  final String customerName; // Denormalized for easier display
  final double quantity; // Quantity of the product/service
  final double agreedAmount; // The amount customer agreed to pay
  final DateTime? eventDate;
  final DateTime?
  expectedFinishingDate; // Expected completion date for the task/event
  final String status; // 'active', 'completed', 'cancelled'

  CustomerEvent({
    required this.eventNo,
    required this.eventName,
    required this.custId,
    required this.productId,
    required this.customerName,
    required this.quantity,
    required this.agreedAmount,
    this.eventDate,
    this.expectedFinishingDate,
    this.status = 'active',
  });

  // Convert CustomerEvent object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'Event_No': eventNo,
      'Event_Name': eventName,
      'Cust_ID': custId,
      'Product_ID': productId,
      'Customer_Name': customerName,
      'Quantity': quantity,
      'Agreed_Amount': agreedAmount,
      'Event_Date': eventDate?.toIso8601String(),
      'Expected_Finishing_Date': expectedFinishingDate?.toIso8601String(),
      'Status': status,
    };
  }

  // Create CustomerEvent object from Map (database result)
  factory CustomerEvent.fromMap(Map<String, dynamic> map) {
    return CustomerEvent(
      eventNo: map['Event_No'] ?? '',
      eventName: map['Event_Name'] ?? '',
      custId: map['Cust_ID'] ?? '',
      productId: map['Product_ID'] ?? '',
      customerName: map['Customer_Name'] ?? '',
      quantity: _toDouble(map['Quantity'] ?? 1.0),
      agreedAmount: _toDouble(map['Agreed_Amount'] ?? 0.0),
      eventDate: map['Event_Date'] != null
          ? DateTime.parse(map['Event_Date'])
          : null,
      expectedFinishingDate: map['Expected_Finishing_Date'] != null
          ? DateTime.parse(map['Expected_Finishing_Date'])
          : null,
      status: map['Status'] ?? 'active',
    );
  }

  // Create a copy of CustomerEvent with updated fields
  CustomerEvent copyWith({
    String? eventNo,
    String? eventName,
    String? custId,
    String? productId,
    String? customerName,
    double? quantity,
    double? agreedAmount,
    DateTime? eventDate,
    DateTime? expectedFinishingDate,
    String? status,
  }) {
    return CustomerEvent(
      eventNo: eventNo ?? this.eventNo,
      eventName: eventName ?? this.eventName,
      custId: custId ?? this.custId,
      productId: productId ?? this.productId,
      customerName: customerName ?? this.customerName,
      quantity: quantity ?? this.quantity,
      agreedAmount: agreedAmount ?? this.agreedAmount,
      eventDate: eventDate ?? this.eventDate,
      expectedFinishingDate:
          expectedFinishingDate ?? this.expectedFinishingDate,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'CustomerEvent{eventNo: $eventNo, eventName: $eventName, custId: $custId, productId: $productId, customerName: $customerName, quantity: $quantity, agreedAmount: $agreedAmount, eventDate: $eventDate, expectedFinishingDate: $expectedFinishingDate, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerEvent && other.eventNo == eventNo;
  }

  // Helper method to safely convert any numeric value to double
  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  int get hashCode {
    return eventNo.hashCode;
  }
}
