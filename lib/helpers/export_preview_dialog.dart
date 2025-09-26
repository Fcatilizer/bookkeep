import 'package:flutter/material.dart';
import '../models/customer_event.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';

class ExportPreviewDialog extends StatefulWidget {
  final CustomerEvent event;

  const ExportPreviewDialog({super.key, required this.event});

  static Future<void> showExportPreviewDialog(
    BuildContext context,
    CustomerEvent event,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: ExportPreviewDialog(event: event),
          ),
        );
      },
    );
  }

  @override
  State<ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<ExportPreviewDialog>
    with TickerProviderStateMixin {
  final ExportService _exportService = ExportService();
  final SettingsService _settingsService = SettingsService();
  late TabController _tabController;

  String? _a4HtmlContent;
  String? _thermalHtmlContent;
  List<Map<String, dynamic>> _dailyEvents = [];

  // Settings variables
  String _companyName = 'BOOKKEEP ACCOUNTING';
  String _companyAddress = 'Customer Event Report';
  String _phoneNumber = '';
  String _gstNumber = '';

  bool _isLoading = true;
  bool _isSavingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load settings first
      final settings = await _settingsService.getAllSettings();
      _companyName = settings['companyName'] ?? 'BOOKKEEP ACCOUNTING';
      _companyAddress = settings['companyAddress'] ?? 'Customer Event Report';
      _phoneNumber = settings['phoneNumber'] ?? '';
      _gstNumber = settings['gstNumber'] ?? '';

      // Load daily activity
      final dailyEvents = await _exportService.getDailyEventsForExport(
        widget.event.eventNo,
      );

      // Generate HTML content for both formats
      final a4Html = await _exportService.generateA4HtmlTemplate(
        widget.event,
        dailyEvents,
      );
      final thermalHtml = await _exportService.generateThermalHtmlTemplate(
        widget.event,
        dailyEvents,
      );

      setState(() {
        _dailyEvents = dailyEvents;
        _a4HtmlContent = a4Html;
        _thermalHtmlContent = thermalHtml;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading preview: $e')));
      }
    }
  }

  Future<void> _savePdf(bool isA4Format) async {
    setState(() {
      _isSavingPdf = true;
    });

    try {
      final htmlContent = isA4Format ? _a4HtmlContent : _thermalHtmlContent;
      final formatName = isA4Format ? 'A4' : 'Thermal';
      final fileName =
          '${widget.event.eventNo}_${formatName}_${DateTime.now().millisecondsSinceEpoch}';

      if (htmlContent != null) {
        // Set the current event for PDF generation
        _exportService.setCurrentEventForPdf(widget.event);

        final savedPath = await _exportService.saveAsPdf(
          htmlContent,
          fileName,
          isA4: isA4Format,
        );

        if (savedPath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved successfully!\\nLocation: $savedPath'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(label: 'OK', onPressed: () {}),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to save PDF')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving PDF: $e')));
      }
    } finally {
      setState(() {
        _isSavingPdf = false;
      });
    }
  }

  Widget _buildA4Preview() {
    final totalSpent = _dailyEvents.fold(0.0, (sum, event) {
      final amount = (event['Amount'] is int)
          ? (event['Amount'] as int).toDouble()
          : (event['Amount'] as double? ?? 0.0);
      return sum + amount;
    });

    final remaining = widget.event.agreedAmount - totalSpent;
    final isOverBudget = totalSpent > widget.event.agreedAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _companyName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _companyAddress,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.visible,
                    ),
                    if (_phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Phone: $_phoneNumber',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_gstNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'GST: $_gstNumber',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Event Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.eventName,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Event No:',
                                widget.event.eventNo,
                              ),
                              _buildDetailRow(
                                'Customer:',
                                widget.event.customerName,
                              ),
                              _buildDetailRow(
                                'Customer ID:',
                                widget.event.custId,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                'Product ID:',
                                widget.event.productId,
                              ),
                              _buildDetailRow(
                                'Quantity:',
                                widget.event.quantity.toString(),
                              ),
                              _buildDetailRow(
                                'Status:',
                                widget.event.status.toUpperCase(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.event.eventDate != null)
                      _buildDetailRow(
                        'Date:',
                        '${widget.event.eventDate!.day}/${widget.event.eventDate!.month}/${widget.event.eventDate!.year}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Financial Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.primaryContainer,
                  border: Border.all(
                    color: isOverBudget
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Summary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildAmountRow(
                      'Agreed Amount:',
                      widget.event.agreedAmount,
                      Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),

                    if (_dailyEvents.isNotEmpty) ...[
                      Text(
                        'Expense Breakdown',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ..._dailyEvents.map((dailyEvent) {
                        final amount = (dailyEvent['Amount'] is int)
                            ? (dailyEvent['Amount'] as int).toDouble()
                            : (dailyEvent['Amount'] as double? ?? 0.0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${dailyEvent['Event_Name'] ?? 'Unnamed Event'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      const Divider(
                        thickness: 2,
                        color: null, // Use theme default
                      ),
                    ] else ...[
                      const Text(
                        'No daily activity recorded',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                    ],

                    _buildAmountRow(
                      'Total Spent:',
                      totalSpent,
                      isOverBudget
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildAmountRow(
                      isOverBudget ? 'Over Budget:' : 'Remaining:',
                      remaining.abs(),
                      isOverBudget
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                child: Text(
                  'Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThermalPreview() {
    final totalSpent = _dailyEvents.fold(0.0, (sum, event) {
      final amount = (event['Amount'] is int)
          ? (event['Amount'] as int).toDouble()
          : (event['Amount'] as double? ?? 0.0);
      return sum + amount;
    });

    final remaining = widget.event.agreedAmount - totalSpent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: 300, // Thermal printer width
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.grey[100],
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Text(
                _companyName,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _companyAddress,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.visible,
              ),
              if (_phoneNumber.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Phone: $_phoneNumber',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_gstNumber.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'GST: $_gstNumber',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // Divider line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),

              // Event name
              Text(
                widget.event.eventName,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Event details
              _buildThermalDetailRow('Event:', widget.event.eventNo),
              _buildThermalDetailRow('Customer:', widget.event.customerName),
              _buildThermalDetailRow('Cust ID:', widget.event.custId),
              _buildThermalDetailRow(
                'Quantity:',
                widget.event.quantity.toString(),
              ),
              _buildThermalDetailRow('Status:', widget.event.status),

              const SizedBox(height: 8),

              _buildThermalDetailRow(
                'Agreed Amount:',
                'Rs.${widget.event.agreedAmount.toStringAsFixed(2)}',
              ),

              if (_dailyEvents.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Daily Activity:',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ..._dailyEvents.map((event) {
                  final amount = (event['Amount'] is int)
                      ? (event['Amount'] as int).toDouble()
                      : (event['Amount'] as double? ?? 0.0);
                  return _buildThermalDetailRow(
                    event['Event_Name'] ?? 'Unnamed',
                    'Rs.${amount.toStringAsFixed(2)}',
                  );
                }),
              ],

              // Bottom line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),

              _buildThermalDetailRow(
                'Total Spent:',
                'Rs.${totalSpent.toStringAsFixed(2)}',
                bold: true,
              ),
              _buildThermalDetailRow(
                'Remaining:',
                'Rs.${remaining.toStringAsFixed(2)}',
                bold: true,
              ),

              // Footer line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),

              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildThermalDetailRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab(String format) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading preview...'),
          ],
        ),
      );
    }

    final isA4 = format == 'A4';

    return Column(
      children: [
        // Format info bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              Icon(
                isA4 ? Icons.description : Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '$format Format Preview',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                isA4 ? '210 × 297 mm' : '80mm width',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Preview content
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: isA4 ? _buildA4Preview() : _buildThermalPreview(),
          ),
        ),
        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isSavingPdf ? null : () => _savePdf(isA4),
                icon: _isSavingPdf
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isSavingPdf ? 'Saving...' : 'Save PDF'),
              ),
              ElevatedButton.icon(
                onPressed: null, // Disabled for now as requested
                icon: const Icon(Icons.print),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Export Preview - ${widget.event.eventName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'A4 Format'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Thermal Format'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            tooltip: 'Close',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPreviewTab('A4'), _buildPreviewTab('Thermal')],
      ),
    );
  }
}
