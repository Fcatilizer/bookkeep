class Customer {
  final String custId;
  final String customerName;
  final String location;
  final String contactPerson;
  final String mobileNo;
  final String gstNo;

  Customer({
    required this.custId,
    required this.customerName,
    required this.location,
    required this.contactPerson,
    required this.mobileNo,
    required this.gstNo,
  });

  // Convert Customer object to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'Cust_ID': custId,
      'Customer_Name': customerName,
      'Location': location,
      'Contact_Person': contactPerson,
      'Mobile_No': mobileNo,
      'GST_No': gstNo,
    };
  }

  // Create Customer object from Map (database result)
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      custId: map['Cust_ID'] ?? '',
      customerName: map['Customer_Name'] ?? '',
      location: map['Location'] ?? '',
      contactPerson: map['Contact_Person'] ?? '',
      mobileNo: map['Mobile_No'] ?? '',
      gstNo: map['GST_No'] ?? '',
    );
  }

  // Create a copy of Customer with updated fields
  Customer copyWith({
    String? custId,
    String? customerName,
    String? location,
    String? contactPerson,
    String? mobileNo,
    String? gstNo,
  }) {
    return Customer(
      custId: custId ?? this.custId,
      customerName: customerName ?? this.customerName,
      location: location ?? this.location,
      contactPerson: contactPerson ?? this.contactPerson,
      mobileNo: mobileNo ?? this.mobileNo,
      gstNo: gstNo ?? this.gstNo,
    );
  }

  @override
  String toString() {
    return 'Customer{custId: $custId, customerName: $customerName, location: $location, contactPerson: $contactPerson, mobileNo: $mobileNo, gstNo: $gstNo}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.custId == custId;
  }

  @override
  int get hashCode {
    return custId.hashCode;
  }
}
