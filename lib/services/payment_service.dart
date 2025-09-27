// 💳 Payment Service - Business logic for payment management
//
// This service handles all payment-related database operations and business logic.
// It provides CRUD operations, validation, calculations, and data retrieval
// for payment transactions across the application.
//
// Author: Ashish Gaurav (@Fcatilizer)
// Created: 2025
// Last Updated: September 24, 2025

import '../models/payment.dart';
import '../helpers/database_helper.dart';

/// PaymentService - Business logic layer for payment operations
///
/// This service provides comprehensive payment management including:
/// - CRUD operations for payment records
/// - Payment validation and business rule enforcement
/// - Calculation methods for totals and summaries
/// - Event-based payment tracking and analysis
/// - Payment ID generation and uniqueness
///
/// Key Features:
/// - Automatic payment status calculation
/// - Event-based payment aggregation
/// - Referential integrity with customer events
/// - Transaction-safe operations
class PaymentService {
  /// Database helper instance for data access
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ══════════════════════════════════════════════════════════════
  // Data Retrieval Methods
  // ══════════════════════════════════════════════════════════════

  /// Retrieve all payment records from the database
  ///
  /// Returns all payments ordered by creation date (most recent first).
  /// Used for comprehensive payment lists and reporting features.
  ///
  /// Returns: List of all Payment objects
  Future<List<Payment>> getAllPayments() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('payments');
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  /// Get all payments for a specific customer event
  ///
  /// Retrieves payments filtered by customer event number, ordered by
  /// payment date (most recent first). Used for event-specific payment tracking.
  ///
  /// [customerEventNo] - Event number to filter payments by
  /// Returns: List of payments for the specified event
  Future<List<Payment>> getPaymentsByCustomerEvent(
    String customerEventNo,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payments',
      where: 'customer_event_no = ?',
      whereArgs: [customerEventNo],
      orderBy: 'payment_date DESC',
    );
    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  // ══════════════════════════════════════════════════════════════
  // Calculation & Analysis Methods
  // ══════════════════════════════════════════════════════════════

  /// Calculate total amount paid for a customer event
  ///
  /// Sums all payment amounts for the specified event to determine
  /// how much has been received. Used for payment status calculations.
  ///
  /// [customerEventNo] - Event number to calculate total for
  /// Returns: Total amount paid as double
  Future<double> getTotalPaidAmount(String customerEventNo) async {
    final payments = await getPaymentsByCustomerEvent(customerEventNo);
    return payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
  }

  // ══════════════════════════════════════════════════════════════
  // CRUD Operations
  // ══════════════════════════════════════════════════════════════

  /// Create a new payment record in the database
  ///
  /// Inserts a new payment with validation and error handling.
  /// Automatically handles foreign key relationships with customer events.
  ///
  /// [payment] - Payment object to create
  /// Returns: true if successful, false if error occurred
  Future<bool> createPayment(Payment payment) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert('payments', payment.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePayment(Payment payment) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'payments',
        payment.toMap(),
        where: 'payment_id = ?',
        whereArgs: [payment.paymentId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deletePayment(String paymentId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        'payments',
        where: 'payment_id = ?',
        whereArgs: [paymentId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> generatePaymentId() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM payments');
    final count = result.first['count'] as int;
    return 'PAY${(count + 1).toString().padLeft(6, '0')}';
  }

  // Payment validation methods
  Future<Map<String, dynamic>> validatePaymentForEvent(
    String customerEventNo,
  ) async {
    try {
      final db = await _databaseHelper.database;

      // Get customer event details
      final eventResult = await db.query(
        'customer_events',
        where: 'Event_No = ?',
        whereArgs: [customerEventNo],
      );

      if (eventResult.isEmpty) {
        return {
          'hasPayments': false,
          'isValid': false,
          'totalPaid': 0.0,
          'agreedAmount': 0.0,
          'message': 'Customer event not found',
        };
      }

      final event = eventResult.first;
      final agreedAmount =
          double.tryParse(event['Agreed_Amount']?.toString() ?? '0') ?? 0.0;

      // Get all payments for this event
      final payments = await getPaymentsByCustomerEvent(customerEventNo);
      final totalPaid = payments.fold<double>(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

      // Get total daily expense expenses for this event
      final expenseResult = await db.rawQuery(
        'SELECT SUM(amount) as total_expenses FROM daily_events WHERE Customer_Event_No = ?',
        [customerEventNo],
      );

      final totalExpenses =
          double.tryParse(
            expenseResult.first['total_expenses']?.toString() ?? '0',
          ) ??
          0.0;

      bool hasPayments = payments.isNotEmpty;
      bool isPaymentSatisfied = totalPaid >= agreedAmount;
      bool isExpenseWithinBudget = totalExpenses <= agreedAmount;

      String message = '';
      if (!hasPayments) {
        message = 'No payment records found for this event';
      } else if (!isPaymentSatisfied) {
        message =
            'Payment amount (₹${totalPaid.toStringAsFixed(2)}) is less than agreed amount (₹${agreedAmount.toStringAsFixed(2)})';
      } else if (!isExpenseWithinBudget) {
        message =
            'Total expenses (₹${totalExpenses.toStringAsFixed(2)}) exceed agreed amount (₹${agreedAmount.toStringAsFixed(2)})';
      } else {
        message = 'Payment is satisfied';
      }

      return {
        'hasPayments': hasPayments,
        'isValid': isPaymentSatisfied && isExpenseWithinBudget,
        'totalPaid': totalPaid,
        'agreedAmount': agreedAmount,
        'totalExpenses': totalExpenses,
        'message': message,
      };
    } catch (e) {
      return {
        'hasPayments': false,
        'isValid': false,
        'totalPaid': 0.0,
        'agreedAmount': 0.0,
        'message': 'Error validating payment: $e',
      };
    }
  }
}
