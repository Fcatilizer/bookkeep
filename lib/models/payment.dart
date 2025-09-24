// 💳 Payment Model - Core data structure for payment transactions
//
// This model represents a payment record in the bookkeeping system.
// It handles various payment types, statuses, and provides utility methods
// for data transformation and display formatting.
//
// Author: Ashish Gaurav (@Fcatilizer)
// Created: 2025
// Last Updated: September 24, 2025

/// Payment Model - Represents a financial transaction record
///
/// This class encapsulates all payment-related data including:
/// - Transaction details (amount, type, status)
/// - Customer and event associations
/// - Audit trail (created/updated timestamps)
/// - Display helpers for UI presentation
///
/// Supported Payment Types:
/// - Cash, Cheque, Bank Transfer, UPI, Card, Net Banking, Other, Adjustment
///
/// Payment Statuses:
/// - Pending: No payment received yet
/// - Partial: Some amount paid, balance remaining
/// - Full: Complete payment received
class Payment {
  /// Unique identifier for the payment record
  final String paymentId;

  /// Reference to the associated customer event
  final String customerEventNo;

  /// Name of the person making the payment
  final String payingPersonName;

  /// Type of payment method used (cash, cheque, bank_transfer, upi, etc.)
  final String paymentType;

  /// Payment amount in the system currency
  final double amount;

  /// Current payment status (pending, partial, full)
  final String status;

  /// Optional transaction reference (cheque number, transaction ID, etc.)
  final String? reference;

  /// Additional notes or comments about the payment
  final String? notes;

  /// Date when the payment was made
  final DateTime paymentDate;

  /// Timestamp when the record was created in the system
  final DateTime createdAt;

  /// Timestamp of the last update to this record
  final DateTime? updatedAt;

  /// Constructor for creating a new Payment instance
  ///
  /// All required fields must be provided. Optional fields like [reference]
  /// and [notes] can be null. The [updatedAt] field is automatically set
  /// when the record is modified.
  Payment({
    required this.paymentId,
    required this.customerEventNo,
    required this.payingPersonName,
    required this.paymentType,
    required this.amount,
    required this.status,
    this.reference,
    this.notes,
    required this.paymentDate,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create Payment from database map
  ///
  /// Converts a map (typically from SQLite query result) into a Payment object.
  /// Handles null values with sensible defaults and ensures proper data types.
  ///
  /// [map] - Map containing payment data from database
  /// Returns: New Payment instance with populated fields
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      paymentId: map['payment_id'] ?? '',
      customerEventNo: map['customer_event_no'] ?? '',
      payingPersonName: map['paying_person_name'] ?? '',
      paymentType: map['payment_type'] ?? 'cash',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      reference: map['reference'],
      notes: map['notes'],
      paymentDate: DateTime.parse(
        map['payment_date'] ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// Convert Payment object to database map format
  ///
  /// Transforms the Payment instance into a Map suitable for database storage.
  /// All DateTime objects are converted to ISO8601 strings for persistence.
  ///
  /// Returns: Map<String, dynamic> ready for database insertion/update
  Map<String, dynamic> toMap() {
    return {
      'payment_id': paymentId,
      'customer_event_no': customerEventNo,
      'paying_person_name': payingPersonName,
      'payment_type': paymentType,
      'amount': amount,
      'status': status,
      'reference': reference,
      'notes': notes,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this Payment with specified fields updated
  ///
  /// This method is useful for updating payment records while maintaining
  /// immutability. Only the provided fields will be changed in the new instance.
  ///
  /// Example:
  /// ```dart
  /// final updatedPayment = payment.copyWith(
  ///   status: 'full',
  ///   updatedAt: DateTime.now(),
  /// );
  /// ```
  ///
  /// Returns: New Payment instance with updated fields
  Payment copyWith({
    String? paymentId,
    String? customerEventNo,
    String? payingPersonName,
    String? paymentType,
    double? amount,
    String? status,
    String? reference,
    String? notes,
    DateTime? paymentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      paymentId: paymentId ?? this.paymentId,
      customerEventNo: customerEventNo ?? this.customerEventNo,
      payingPersonName: payingPersonName ?? this.payingPersonName,
      paymentType: paymentType ?? this.paymentType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Static Configuration & Constants
  // ══════════════════════════════════════════════════════════════

  /// Available payment status options
  ///
  /// - pending: Payment not yet received
  /// - partial: Some amount paid, balance remaining
  /// - full: Complete payment received
  static List<String> get paymentStatuses => ['pending', 'partial', 'full'];

  /// Supported payment method types
  ///
  /// Comprehensive list covering all common payment methods including:
  /// - Traditional: cash, cheque, bank_transfer
  /// - Digital: upi, card, netbanking
  /// - Special: other, adjustment (for corrections/refunds)
  static List<String> get paymentTypes => [
    'cash',
    'cheque',
    'bank_transfer',
    'upi',
    'card',
    'netbanking',
    'other',
    'adjustment',
  ];

  // ══════════════════════════════════════════════════════════════
  // Display Helper Methods
  // ══════════════════════════════════════════════════════════════

  /// Convert payment status code to user-friendly display name
  ///
  /// Transforms internal status codes into readable labels for UI display.
  /// Used in dropdowns, filters, and payment status indicators.
  ///
  /// [status] - Internal status code (pending, partial, full)
  /// Returns: Human-readable status label
  static String getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'partial':
        return 'Partial Payment';
      case 'full':
        return 'Full Payment';
      default:
        return status;
    }
  }

  /// Convert payment type code to user-friendly display name
  ///
  /// Transforms internal payment type codes into readable labels for UI.
  /// Used in payment method dropdowns, chips, and transaction displays.
  ///
  /// [type] - Internal payment type code (cash, upi, etc.)
  /// Returns: Human-readable payment method label
  static String getPaymentTypeDisplayName(String type) {
    switch (type) {
      case 'cash':
        return 'Cash';
      case 'cheque':
        return 'Cheque';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'Card';
      case 'netbanking':
        return 'Net Banking';
      case 'other':
        return 'Other';
      case 'adjustment':
        return 'Adjustment';
      default:
        return type;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Convenience Getters
  // ══════════════════════════════════════════════════════════════

  /// Get human-readable status name for this payment
  String get statusDisplayName => getStatusDisplayName(status);

  /// Get human-readable payment type name for this payment
  String get paymentTypeDisplayName => getPaymentTypeDisplayName(paymentType);
}
