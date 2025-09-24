import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/event.dart';
import '../models/customer_event.dart';
import '../models/expense_type.dart';
import '../models/payment_mode.dart';
import '../models/payment.dart';

class CsvExportService {
  static Future<String> exportCustomersToCSV(List<Customer> customers) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'Customer ID',
      'Customer Name',
      'Mobile No',
      'Contact Person',
      'GST No',
      'Location',
    ]);

    // Add data rows
    for (Customer customer in customers) {
      rows.add([
        customer.custId,
        customer.customerName,
        customer.mobileNo,
        customer.contactPerson,
        customer.gstNo,
        customer.location,
      ]);
    }

    return await _saveCSVFile(rows, 'customers_export');
  }

  static Future<String> exportProductsToCSV(List<Product> products) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add(['Product ID', 'Product Name', 'Tax Rate (%)']);

    // Add data rows
    for (Product product in products) {
      rows.add([product.productId, product.productName, product.taxRate]);
    }

    return await _saveCSVFile(rows, 'products_export');
  }

  static Future<String> exportEventsToCSV(List<Event> events) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'Event No',
      'Event Name',
      'Customer ID',
      'Customer Name',
      'Product ID',
      'Expense Type',
      'Expense Name',
      'Amount',
      'Event Date',
      'Customer Event No',
    ]);

    // Add data rows
    for (Event event in events) {
      rows.add([
        event.eventNo,
        event.eventName,
        event.custId,
        event.customerName,
        event.productId,
        event.expenseType,
        event.expenseName,
        event.amount,
        event.eventDate?.toIso8601String() ?? '',
        event.customerEventNo ?? '',
      ]);
    }

    return await _saveCSVFile(rows, 'events_export');
  }

  static Future<String> exportCustomerEventsToCSV(
    List<CustomerEvent> customerEvents,
  ) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'Event No',
      'Event Name',
      'Customer ID',
      'Customer Name',
      'Product ID',
      'Quantity',
      'Agreed Amount',
      'Event Date',
      'Expected Finish Date',
      'Status',
    ]);

    // Add data rows
    for (CustomerEvent event in customerEvents) {
      rows.add([
        event.eventNo,
        event.eventName,
        event.custId,
        event.customerName,
        event.productId,
        event.quantity,
        event.agreedAmount,
        event.eventDate?.toIso8601String() ?? '',
        event.expectedFinishingDate?.toIso8601String() ?? '',
        event.status,
      ]);
    }

    return await _saveCSVFile(rows, 'customer_events_export');
  }

  static Future<String> _saveCSVFile(
    List<List<dynamic>> rows,
    String fileName,
  ) async {
    try {
      // Convert to CSV
      String csvData = const ListToCsvConverter().convert(rows);

      // Get Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid || Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Create file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${downloadsDir.path}/${fileName}_$timestamp.csv');

      // Write to file
      await file.writeAsString(csvData);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export CSV: $e');
    }
  }

  static Future<String> exportExpenseTypesToCSV(
    List<ExpenseType> expenseTypes,
  ) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'Expense Type ID',
      'Expense Type Name',
      'Category',
      'Description',
      'Status',
      'Created Date',
    ]);

    // Add data rows
    for (ExpenseType expenseType in expenseTypes) {
      rows.add([
        expenseType.expenseTypeId,
        expenseType.expenseTypeName,
        expenseType.category,
        expenseType.description ?? '',
        expenseType.isActive ? 'Active' : 'Inactive',
        '${expenseType.createdAt.day}/${expenseType.createdAt.month}/${expenseType.createdAt.year}',
      ]);
    }

    return await _saveCSVFile(rows, 'expense_types_export');
  }

  static Future<String> exportPaymentModesToCSV(
    List<PaymentMode> paymentModes,
  ) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'Payment Mode ID',
      'Payment Mode Name',
      'Type',
      'Description',
      'Status',
      'Created Date',
    ]);

    // Add data rows
    for (PaymentMode paymentMode in paymentModes) {
      rows.add([
        paymentMode.paymentModeId,
        paymentMode.paymentModeName,
        paymentMode.typeDisplayName,
        paymentMode.description ?? '',
        paymentMode.isActive ? 'Active' : 'Inactive',
        '${paymentMode.createdAt.day}/${paymentMode.createdAt.month}/${paymentMode.createdAt.year}',
      ]);
    }

    return await _saveCSVFile(rows, 'payment_modes_export');
  }

  static Future<String> exportPaymentsToCSV(List<Payment> payments) async {
    List<List<dynamic>> rows = [];

    // Add header
    rows.add([
      'Payment ID',
      'Customer Event No',
      'Paying Person Name',
      'Payment Type',
      'Amount',
      'Status',
      'Reference',
      'Notes',
      'Payment Date',
      'Created At',
    ]);

    // Add data rows
    for (Payment payment in payments) {
      rows.add([
        payment.paymentId,
        payment.customerEventNo,
        payment.payingPersonName,
        payment.paymentType,
        payment.amount.toString(),
        payment.status,
        payment.reference ?? '',
        payment.notes ?? '',
        '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
        '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
      ]);
    }

    return await _saveCSVFile(rows, 'payments_export');
  }
}
