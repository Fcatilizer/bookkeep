class Event {
  final String eventNo;
  final String eventName;
  final String custId;
  final String productId;
  final String customerName; // Denormalized for easier display
  final String expenseType;
  final String expenseName;
  final double amount;
  final DateTime? eventDate; // Added for better event tracking
  final String? customerEventNo; // Link to customer event (optional)

  Event({
    required this.eventNo,
    required this.eventName,
    required this.custId,
    required this.productId,
    required this.customerName,
    required this.expenseType,
    required this.expenseName,
    required this.amount,
    this.eventDate,
    this.customerEventNo,
  });

  // Convert Event object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'Event_No': eventNo,
      'Event_Name': eventName,
      'Cust_ID': custId,
      'Product_ID': productId,
      'Customer_Name': customerName,
      'Expense_Type': expenseType,
      'Expense_Name': expenseName,
      'Amount': amount,
      'Event_Date': eventDate?.toIso8601String(),
      'Customer_Event_No': customerEventNo,
    };
  }

  // Create Event object from Map (database result)
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      eventNo: map['Event_No'] ?? '',
      eventName: map['Event_Name'] ?? '',
      custId: map['Cust_ID'] ?? '',
      productId: map['Product_ID'] ?? '',
      customerName: map['Customer_Name'] ?? '',
      expenseType: map['Expense_Type'] ?? '',
      expenseName: map['Expense_Name'] ?? '',
      amount: (map['Amount'] ?? 0.0).toDouble(),
      eventDate: map['Event_Date'] != null
          ? DateTime.parse(map['Event_Date'])
          : null,
      customerEventNo: map['Customer_Event_No'],
    );
  }

  // Create a copy of Event with updated fields
  Event copyWith({
    String? eventNo,
    String? eventName,
    String? custId,
    String? productId,
    String? customerName,
    String? expenseType,
    String? expenseName,
    double? amount,
    DateTime? eventDate,
    String? customerEventNo,
  }) {
    return Event(
      eventNo: eventNo ?? this.eventNo,
      eventName: eventName ?? this.eventName,
      custId: custId ?? this.custId,
      productId: productId ?? this.productId,
      customerName: customerName ?? this.customerName,
      expenseType: expenseType ?? this.expenseType,
      expenseName: expenseName ?? this.expenseName,
      amount: amount ?? this.amount,
      eventDate: eventDate ?? this.eventDate,
      customerEventNo: customerEventNo ?? this.customerEventNo,
    );
  }

  @override
  String toString() {
    return 'Event{eventNo: $eventNo, eventName: $eventName, custId: $custId, productId: $productId, customerName: $customerName, expenseType: $expenseType, expenseName: $expenseName, amount: $amount, eventDate: $eventDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.eventNo == eventNo;
  }

  @override
  int get hashCode {
    return eventNo.hashCode;
  }
}
