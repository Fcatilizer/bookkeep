import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/customer_event.dart';
import 'customer_event_service.dart';
import 'product_service.dart';
import 'settings_service.dart';

class ExportService {
  final CustomerEventService _customerEventService = CustomerEventService();
  final SettingsService _settingsService = SettingsService();
  final ProductService _productService = ProductService();

  // Helper method to calculate tax breakdown
  Future<Map<String, double>> _calculateTaxBreakdown(
    CustomerEvent event,
  ) async {
    try {
      final product = await _productService.getProductById(event.productId);

      if (product != null && product.taxRate > 0) {
        // Calculate base amount from agreed amount (reverse calculation)
        // agreed amount = base amount + (base amount * tax rate / 100)
        // agreed amount = base amount * (1 + tax rate / 100)
        // base amount = agreed amount / (1 + tax rate / 100)
        final double baseAmount =
            event.agreedAmount / (1 + (product.taxRate / 100));
        final double taxAmount = event.agreedAmount - baseAmount;

        return {
          'baseAmount': baseAmount,
          'taxAmount': taxAmount,
          'taxRate': product.taxRate,
          'totalAmount': event.agreedAmount,
        };
      }
    } catch (e) {
      print('Error calculating tax breakdown: $e');
    }

    // If no product found or no tax, return the agreed amount as base
    return {
      'baseAmount': event.agreedAmount,
      'taxAmount': 0.0,
      'taxRate': 0.0,
      'totalAmount': event.agreedAmount,
    };
  }

  // Generate HTML template for A4 format
  Future<String> generateA4HtmlTemplate(
    CustomerEvent event,
    List<Map<String, dynamic>> dailyEvents,
  ) async {
    final double totalSpent = dailyEvents.fold(0.0, (sum, event) {
      final amount = (event['Amount'] is int)
          ? (event['Amount'] as int).toDouble()
          : (event['Amount'] as double? ?? 0.0);
      return sum + amount;
    });

    final double remaining = event.agreedAmount - totalSpent;
    final bool isOverBudget = totalSpent > event.agreedAmount;

    // Get tax breakdown
    final taxBreakdown = await _calculateTaxBreakdown(event);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Event Report - ${event.eventName}</title>
    <style>
        @page {
            size: A4;
            margin: 20mm;
        }
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #000;
            margin: 0;
            padding: 0;
        }
        .header {
            text-align: center;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 20px;
            margin-bottom: 30px;
        }
        .company-name {
            font-size: 28px;
            font-weight: bold;
            color: #2E7D32;
            margin-bottom: 5px;
        }
        .report-title {
            font-size: 18px;
            color: #000;
        }
        .event-details {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 25px;
        }
        .event-title {
            font-size: 24px;
            font-weight: bold;
            color: #2E7D32;
            margin-bottom: 15px;
        }
        .details-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }
        .detail-item {
            display: flex;
            justify-content: space-between;
            padding: 8px 0;
            border-bottom: 1px solid #000;
        }
        .detail-label {
            font-weight: bold;
            color: #000;
        }
        .financial-summary {
            background: white;
            border: 2px solid #4CAF50;
            border-radius: 8px;
            padding: 20px;
            margin: 25px 0;
        }
        .summary-title {
            font-size: 20px;
            font-weight: bold;
            color: #2E7D32;
            margin-bottom: 20px;
            text-align: center;
        }
        .amount-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            font-size: 16px;
        }
        .amount-label {
            font-weight: bold;
        }
        .amount-value {
            font-weight: bold;
        }
        .agreed-amount { color: #2196F3; }
        .spent-amount { color: ${isOverBudget ? '#f44336' : '#4CAF50'}; }
        .remaining-amount { color: ${isOverBudget ? '#f44336' : '#4CAF50'}; }
        .daily-activity {
            margin: 20px 0;
        }
        .daily-activity-title {
            font-size: 18px;
            font-weight: bold;
            color: #000;
            margin-bottom: 15px;
            padding-bottom: 8px;
            border-bottom: 1px solid #000;
        }
        .event-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 15px;
            margin: 5px 0;
            background: #f5f5f5;
            border-left: 4px solid #4CAF50;
            border-radius: 4px;
        }
        .event-name {
            font-weight: 500;
        }
        .event-amount {
            font-weight: bold;
            color: #2E7D32;
        }
        .divider {
            border-top: 2px solid #4CAF50;
            margin: 20px 0;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #000;
            font-size: 12px;
            color: #000;
        }
        .status-${event.status} {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
            background: ${event.status == 'active' ? '#4CAF50' : '#000'};
            color: white;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">BookKeep Accounting</div>
        <div class="report-title">Customer Event Report</div>
    </div>

    <div class="event-details">
        <div class="event-title">${event.eventName}</div>
        <div class="details-grid">
            <div class="detail-item">
                <span class="detail-label">Event No:</span>
                <span>${event.eventNo}</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Customer:</span>
                <span>${event.customerName}</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Customer ID:</span>
                <span>${event.custId}</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Product ID:</span>
                <span>${event.productId}</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Quantity:</span>
                <span>${event.quantity}</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Status:</span>
                <span class="status-${event.status}">${event.status}</span>
            </div>
            ${event.eventDate != null ? '''
            <div class="detail-item">
                <span class="detail-label">Date:</span>
                <span>${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}</span>
            </div>
            ''' : ''}
        </div>
    </div>

    <div class="financial-summary">
        <div class="summary-title">Financial Summary</div>
        
        ${(taxBreakdown['taxRate'] as double) > 0 ? '''
        <div class="amount-row">
            <span class="amount-label">Base Amount:</span>
            <span class="amount-value">₹${(taxBreakdown['baseAmount'] as double).toStringAsFixed(2)}</span>
        </div>
        <div class="amount-row">
            <span class="amount-label">Tax (${(taxBreakdown['taxRate'] as double).toStringAsFixed(1)}%):</span>
            <span class="amount-value">₹${(taxBreakdown['taxAmount'] as double).toStringAsFixed(2)}</span>
        </div>
        <div class="amount-row">
            <span class="amount-label">Total Amount:</span>
            <span class="amount-value agreed-amount">₹${(taxBreakdown['totalAmount'] as double).toStringAsFixed(2)}</span>
        </div>
        ''' : '''
        <div class="amount-row">
            <span class="amount-label">Agreed Amount:</span>
            <span class="amount-value agreed-amount">₹${event.agreedAmount.toStringAsFixed(2)}</span>
        </div>
        '''}

        ${dailyEvents.isNotEmpty ? '''
        <div class="daily-activity">
            <div class="daily-activity-title">Expenses Breakdown</div>
            ${dailyEvents.map((dailyEvent) {
            final amount = (dailyEvent['Amount'] is int) ? (dailyEvent['Amount'] as int).toDouble() : (dailyEvent['Amount'] as double? ?? 0.0);
            return '''
              <div class="event-item">
                  <span class="event-name">${dailyEvent['Event_Name'] ?? 'Unnamed Event'}</span>
                  <span class="event-amount">₹${amount.toStringAsFixed(2)}</span>
              </div>
              ''';
          }).join('')}
        </div>
        ''' : '<div class="daily-activity-title">No daily activity recorded</div>'}

        <div class="divider"></div>
        
        <div class="amount-row">
            <span class="amount-label">Total Spent:</span>
            <span class="amount-value spent-amount">₹${totalSpent.toStringAsFixed(2)}</span>
        </div>
        
        <div class="amount-row">
            <span class="amount-label">${isOverBudget ? 'Over Budget:' : 'Remaining:'}</span>
            <span class="amount-value remaining-amount">₹${remaining.abs().toStringAsFixed(2)}</span>
        </div>
    </div>

    <div class="footer">
        Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}
    </div>
</body>
</html>
    ''';
  }

  // Generate HTML template for thermal printer format
  Future<String> generateThermalHtmlTemplate(
    CustomerEvent event,
    List<Map<String, dynamic>> dailyEvents,
  ) async {
    final double totalSpent = dailyEvents.fold(0.0, (sum, event) {
      final amount = (event['Amount'] is int)
          ? (event['Amount'] as int).toDouble()
          : (event['Amount'] as double? ?? 0.0);
      return sum + amount;
    });

    final double remaining = event.agreedAmount - totalSpent;
    final bool isOverBudget = totalSpent > event.agreedAmount;

    // Get tax breakdown for thermal template
    final taxBreakdown = await _calculateTaxBreakdown(event);

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Thermal Receipt - ${event.eventName}</title>
    <style>
        @page {
            size: 80mm auto;
            margin: 5mm;
        }
        body {
            font-family: 'Courier New', monospace;
            font-size: 11px;
            line-height: 1.2;
            margin: 0;
            padding: 0;
            width: 70mm;
        }
        .header {
            text-align: center;
            margin-bottom: 15px;
            border-bottom: 1px solid #000;
            padding-bottom: 10px;
        }
        .company-name {
            font-size: 14px;
            font-weight: bold;
            margin-bottom: 3px;
        }
        .report-title {
            font-size: 10px;
            margin-bottom: 5px;
        }
        .divider {
            border-top: 1px dashed #000;
            margin: 8px 0;
        }
        .row {
            display: flex;
            justify-content: space-between;
            margin: 2px 0;
            word-wrap: break-word;
        }
        .label {
            font-weight: bold;
            width: 45%;
        }
        .value {
            width: 50%;
            text-align: right;
        }
        .event-title {
            font-weight: bold;
            margin: 8px 0;
            text-align: center;
            word-wrap: break-word;
        }
        .daily-event {
            margin: 3px 0;
            font-size: 10px;
        }
        .daily-event-row {
            display: flex;
            justify-content: space-between;
            margin: 1px 0;
        }
        .event-name {
            width: 65%;
            word-wrap: break-word;
            font-size: 9px;
        }
        .event-amount {
            width: 30%;
            text-align: right;
            font-weight: bold;
        }
        .total-row {
            font-weight: bold;
            border-top: 1px solid #000;
            border-bottom: 1px solid #000;
            padding: 3px 0;
            margin: 5px 0;
        }
        .footer {
            text-align: center;
            font-size: 8px;
            margin-top: 10px;
            border-top: 1px solid #000;
            padding-top: 5px;
        }
        .status {
            text-align: center;
            font-weight: bold;
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">BOOKKEEP ACCOUNTING</div>
        <div class="report-title">Customer Event Report</div>
    </div>

    <div class="event-title">${event.eventName}</div>
    
    <div class="row">
        <span class="label">Event No:</span>
        <span class="value">${event.eventNo}</span>
    </div>
    
    <div class="row">
        <span class="label">Customer:</span>
        <span class="value">${event.customerName}</span>
    </div>
    
    <div class="row">
        <span class="label">Cust ID:</span>
        <span class="value">${event.custId}</span>
    </div>
    
    <div class="row">
        <span class="label">Quantity:</span>
        <span class="value">${event.quantity}</span>
    </div>
    
    <div class="status">STATUS: ${event.status.toUpperCase()}</div>
    
    ${event.eventDate != null ? '''
    <div class="row">
        <span class="label">Date:</span>
        <span class="value">${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}</span>
    </div>
    ''' : ''}

    <div class="divider"></div>
    
    ${(taxBreakdown['taxRate'] as double) > 0 ? '''
    <div class="row">
        <span class="label">Base Amt:</span>
        <span class="value">₹${(taxBreakdown['baseAmount'] as double).toStringAsFixed(2)}</span>
    </div>
    <div class="row">
        <span class="label">Tax (${(taxBreakdown['taxRate'] as double).toStringAsFixed(1)}%):</span>
        <span class="value">₹${(taxBreakdown['taxAmount'] as double).toStringAsFixed(2)}</span>
    </div>
    <div class="row">
        <span class="label">Total Amt:</span>
        <span class="value">₹${(taxBreakdown['totalAmount'] as double).toStringAsFixed(2)}</span>
    </div>
    ''' : '''
    <div class="row">
        <span class="label">Agreed Amt:</span>
        <span class="value">₹${event.agreedAmount.toStringAsFixed(2)}</span>
    </div>
    '''}

    ${dailyEvents.isNotEmpty ? '''
    <div class="divider"></div>
    <div style="text-align: center; font-weight: bold; margin: 5px 0;">DAILY ACTIVITY</div>
    ${dailyEvents.map((dailyEvent) {
            final amount = (dailyEvent['Amount'] is int) ? (dailyEvent['Amount'] as int).toDouble() : (dailyEvent['Amount'] as double? ?? 0.0);
            return '''
      <div class="daily-event-row">
          <span class="event-name">${dailyEvent['Event_Name'] ?? 'Unnamed'}</span>
          <span class="event-amount">₹${amount.toStringAsFixed(2)}</span>
      </div>
      ''';
          }).join('')}
    ''' : '<div style="text-align: center; margin: 5px 0;">No daily activity</div>'}

    <div class="total-row">
        <div class="row">
            <span class="label">Total Spent:</span>
            <span class="value">₹${totalSpent.toStringAsFixed(2)}</span>
        </div>
        <div class="row">
            <span class="label">${isOverBudget ? 'Over Budget:' : 'Remaining:'}</span>
            <span class="value">₹${remaining.abs().toStringAsFixed(2)}</span>
        </div>
    </div>

    <div class="footer">
        Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}<br>
        ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}
    </div>
</body>
</html>
    ''';
  }

  // Get daily activity for an event
  Future<List<Map<String, dynamic>>> getDailyEventsForExport(
    String customerEventNo,
  ) async {
    return await _customerEventService.getDailyEventsForCustomerEvent(
      customerEventNo,
    );
  }

  // Save as PDF using native PDF generation
  Future<String?> saveAsPdf(
    String htmlContent,
    String fileName, {
    bool isA4 = true,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName.pdf');

      // Get user settings
      final settings = await _settingsService.getAllSettings();
      final companyName = settings['companyName'] ?? 'BOOKKEEP ACCOUNTING';
      final companyAddress =
          settings['companyAddress'] ?? 'Customer Event Report';
      final phoneNumber = settings['phoneNumber'] ?? '';
      final gstNumber = settings['gstNumber'] ?? '';

      // Create PDF document using pdf package
      final pdf = pw.Document();

      // Parse the customer event data for PDF generation
      // Since we have the HTML content, we'll extract the data we need
      final customerEvent = await _getEventDataForPdf();

      if (customerEvent == null) {
        print('No event data available for PDF generation');
        return null;
      }

      final dailyEvents = await _customerEventService
          .getDailyEventsForCustomerEvent(customerEvent.eventNo);

      // Calculate totals
      final double totalSpent = dailyEvents.fold(0.0, (sum, event) {
        final amount = (event['Amount'] is int)
            ? (event['Amount'] as int).toDouble()
            : (event['Amount'] as double? ?? 0.0);
        return sum + amount;
      });

      final double remaining = customerEvent.agreedAmount - totalSpent;
      final bool isOverBudget = totalSpent > customerEvent.agreedAmount;

      // Add page to PDF
      pdf.addPage(
        pw.Page(
          pageFormat: isA4
              ? PdfPageFormat.a4
              : PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
          build: (pw.Context context) {
            if (isA4) {
              // A4 Complex Layout
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.only(bottom: 20),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 2),
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          companyName,
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: double.infinity,
                          child: pw.Text(
                            companyAddress,
                            style: pw.TextStyle(
                              fontSize: 16,
                              color: PdfColors.black,
                            ),
                            textAlign: pw.TextAlign.center,
                            maxLines: 3,
                            overflow: pw.TextOverflow.visible,
                          ),
                        ),
                        if (phoneNumber.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Phone: $phoneNumber',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                        if (gstNumber.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'GST: $gstNumber',
                            style: pw.TextStyle(
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),

                  // Event Details
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          customerEvent.eventName,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildPdfDetailRow(
                                    'Event No:',
                                    customerEvent.eventNo,
                                  ),
                                  _buildPdfDetailRow(
                                    'Customer:',
                                    customerEvent.customerName,
                                  ),
                                  _buildPdfDetailRow(
                                    'Customer ID:',
                                    customerEvent.custId,
                                  ),
                                ],
                              ),
                            ),
                            pw.SizedBox(width: 20),
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  _buildPdfDetailRow(
                                    'Product ID:',
                                    customerEvent.productId,
                                  ),
                                  _buildPdfDetailRow(
                                    'Quantity:',
                                    customerEvent.quantity.toString(),
                                  ),
                                  _buildPdfDetailRow(
                                    'Status:',
                                    customerEvent.status.toUpperCase(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (customerEvent.eventDate != null) ...[
                          pw.SizedBox(height: 12),
                          _buildPdfDetailRow(
                            'Event Date:',
                            customerEvent.eventDate!.day.toString().padLeft(
                                  2,
                                  '0',
                                ) +
                                '/${customerEvent.eventDate!.month.toString().padLeft(2, '0')}/${customerEvent.eventDate!.year}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),

                  // Financial Summary
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(
                        color: isOverBudget ? PdfColors.red : PdfColors.green,
                        width: 2,
                      ),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Financial Summary',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 16),
                        _buildPdfAmountRow(
                          'Agreed Amount:',
                          customerEvent.agreedAmount,
                        ),
                        pw.SizedBox(height: 12),

                        if (dailyEvents.isNotEmpty) ...[
                          pw.Text(
                            'Expenses Breakdown',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          ...dailyEvents.map((dailyEvent) {
                            final amount = (dailyEvent['Amount'] is int)
                                ? (dailyEvent['Amount'] as int).toDouble()
                                : (dailyEvent['Amount'] as double? ?? 0.0);
                            return pw.Container(
                              padding: const pw.EdgeInsets.all(12),
                              margin: const pw.EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.white,
                                border: pw.Border(
                                  left: pw.BorderSide(
                                    color: PdfColors.green,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    '- ${dailyEvent['Event_Name'] ?? 'Unnamed Event'}',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.normal,
                                    ),
                                  ),
                                  pw.Text(
                                    'Rs.${amount.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.black,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          pw.Container(
                            height: 2,
                            color: PdfColors.green,
                            margin: const pw.EdgeInsets.symmetric(vertical: 20),
                          ),
                        ] else ...[
                          pw.Text(
                            'No daily activity recorded',
                            style: pw.TextStyle(
                              fontStyle: pw.FontStyle.italic,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                        ],

                        _buildPdfAmountRow('Total Spent:', totalSpent),
                        pw.SizedBox(height: 8),
                        _buildPdfAmountRow(
                          isOverBudget ? 'Over Budget:' : 'Remaining:',
                          remaining.abs(),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),

                  // Footer
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                    child: pw.Text(
                      'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.black),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              );
            } else {
              // Simple Thermal Layout with margins
              return pw.Container(
                padding: const pw.EdgeInsets.all(
                  8,
                ), // Add margin from all directions
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // Header
                    pw.Text(
                      companyName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Container(
                      width: double.infinity,
                      child: pw.Text(
                        companyAddress,
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                        maxLines: 3,
                        overflow: pw.TextOverflow.visible,
                      ),
                    ),
                    if (phoneNumber.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Phone: $phoneNumber',
                        style: pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                    if (gstNumber.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'GST: $gstNumber',
                        style: pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Container(height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 6),

                    // Event Name
                    pw.Text(
                      customerEvent.eventName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 6),

                    // Simple details
                    _buildThermalRow('Event:', customerEvent.eventNo),
                    _buildThermalRow('Customer:', customerEvent.customerName),
                    _buildThermalRow('Cust ID:', customerEvent.custId),
                    _buildThermalRow(
                      'Quantity:',
                      customerEvent.quantity.toString(),
                    ),
                    _buildThermalRow('Status:', customerEvent.status),

                    if (customerEvent.eventDate != null)
                      _buildThermalRow(
                        'Date:',
                        '${customerEvent.eventDate!.day}/${customerEvent.eventDate!.month}/${customerEvent.eventDate!.year}',
                      ),

                    pw.SizedBox(height: 4),
                    pw.Container(height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),

                    _buildThermalRow(
                      'Agreed Amount:',
                      'Rs.${customerEvent.agreedAmount.toStringAsFixed(2)}',
                    ),

                    if (dailyEvents.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Daily Activity:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 2),
                      ...dailyEvents.map((event) {
                        final amount = (event['Amount'] is int)
                            ? (event['Amount'] as int).toDouble()
                            : (event['Amount'] as double? ?? 0.0);
                        return _buildThermalRow(
                          event['Event_Name'] ?? 'Unnamed',
                          'Rs.${amount.toStringAsFixed(2)}',
                        );
                      }),
                    ],

                    pw.SizedBox(height: 4),
                    pw.Container(height: 2, color: PdfColors.black),
                    pw.SizedBox(height: 4),

                    _buildThermalRow(
                      'Total Spent:',
                      'Rs.${totalSpent.toStringAsFixed(2)}',
                      bold: true,
                    ),
                    _buildThermalRow(
                      'Remaining:',
                      'Rs.${remaining.toStringAsFixed(2)}',
                      bold: true,
                    ),

                    pw.SizedBox(height: 4),
                    pw.Container(height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),

                    pw.Text(
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                      style: pw.TextStyle(fontSize: 8),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              );
            }
          },
        ),
      );

      // Save PDF
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      print('Error saving PDF: $e');
      return null;
    }
  }

  // Helper method to build detail rows for PDF
  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.Text(value, style: pw.TextStyle(color: PdfColors.black)),
        ],
      ),
    );
  }

  // Helper method to build amount rows for PDF
  pw.Widget _buildPdfAmountRow(String label, double amount) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: PdfColors.black,
          ),
        ),
        pw.Text(
          'Rs.${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: PdfColors.black,
          ),
        ),
      ],
    );
  }

  // Helper method to build thermal PDF rows
  pw.Widget _buildThermalRow(String label, String value, {bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get event data for PDF (this will need to be set from the dialog)
  CustomerEvent? _currentEventForPdf;

  void setCurrentEventForPdf(CustomerEvent event) {
    _currentEventForPdf = event;
  }

  Future<CustomerEvent?> _getEventDataForPdf() async {
    return _currentEventForPdf;
  }
}
