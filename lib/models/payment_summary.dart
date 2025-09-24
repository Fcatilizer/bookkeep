import 'package:flutter/material.dart';
import 'payment.dart';

class PaymentSummary {
  final String customerEventNo;
  final String customerName;
  final String eventName;
  final double agreedAmount;
  final List<Payment> payments;
  final double totalPaid;
  final double remainingAmount;
  final bool isOverpaid;
  final DateTime? lastPaymentDate;
  final String status; // 'not_started', 'partial', 'completed', 'overpaid'
  final String customerEventStatus; // 'active', 'completed', 'cancelled'

  PaymentSummary({
    required this.customerEventNo,
    required this.customerName,
    required this.eventName,
    required this.agreedAmount,
    required this.payments,
    this.customerEventStatus = 'active', // Default to active
  }) : totalPaid = payments.fold(0.0, (sum, payment) => sum + payment.amount),
       remainingAmount =
           agreedAmount -
           payments.fold(0.0, (sum, payment) => sum + payment.amount),
       isOverpaid =
           payments.fold(0.0, (sum, payment) => sum + payment.amount) >
           agreedAmount,
       lastPaymentDate = payments.isEmpty
           ? null
           : payments
                 .map((p) => p.paymentDate)
                 .reduce((a, b) => a.isAfter(b) ? a : b),
       status = _calculateStatus(
         agreedAmount,
         payments.fold(0.0, (sum, payment) => sum + payment.amount),
         customerEventStatus,
       );

  static String _calculateStatus(
    double agreedAmount,
    double totalPaid,
    String customerEventStatus,
  ) {
    // If customer event is cancelled, show cancelled status
    if (customerEventStatus == 'cancelled') {
      return 'cancelled';
    }

    if (totalPaid == 0) return 'not_started';
    if (totalPaid < agreedAmount) return 'partial';
    if (totalPaid == agreedAmount) return 'completed';
    return 'overpaid';
  }

  double get paymentProgress =>
      agreedAmount == 0 ? 0 : (totalPaid / agreedAmount).clamp(0.0, 1.0);

  String get statusDisplayName {
    switch (status) {
      case 'not_started':
        return 'Not Started';
      case 'partial':
        return 'Partial';
      case 'completed':
        return 'Completed';
      case 'overpaid':
        return 'Overpaid';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'not_started':
        return Colors.grey;
      case 'partial':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'overpaid':
        return Colors.red;
      case 'cancelled':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  String get remainingDisplayText {
    if (isOverpaid) {
      return 'Overpaid by ₹${(-remainingAmount).toStringAsFixed(2)}';
    } else if (remainingAmount > 0) {
      return 'Remaining ₹${remainingAmount.toStringAsFixed(2)}';
    } else {
      return 'Fully Paid';
    }
  }
}
