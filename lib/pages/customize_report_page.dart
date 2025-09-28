import 'package:flutter/material.dart';

class CustomizeReportPage extends StatefulWidget {
  const CustomizeReportPage({super.key});

  @override
  State<CustomizeReportPage> createState() => _CustomizeReportPageState();
}

class _CustomizeReportPageState extends State<CustomizeReportPage> {
  // Report customization options
  bool _includeCustomerDetails = true;
  bool _includePaymentSummary = true;
  bool _includeDailyExpenses = true;
  bool _includeEventDetails = true;
  bool _includeExpenseBreakdown = true;
  bool _includeThermalPageOption = false;
  // Removed _reportFormat, _reportLayout, and _dateRange as PDF Layout Section is removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Report'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Content Section
            _buildSectionHeader('Report Content'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Customer Details'),
                    subtitle: const Text(
                      'Include customer information in reports',
                    ),
                    value: _includeCustomerDetails,
                    onChanged: (value) {
                      setState(() {
                        _includeCustomerDetails = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Payment Summary'),
                    subtitle: const Text('Include payment totals and status'),
                    value: _includePaymentSummary,
                    onChanged: (value) {
                      setState(() {
                        _includePaymentSummary = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Daily Expenses'),
                    subtitle: const Text('Include daily expense records'),
                    value: _includeDailyExpenses,
                    onChanged: (value) {
                      setState(() {
                        _includeDailyExpenses = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Event Details'),
                    subtitle: const Text('Include customer event information'),
                    value: _includeEventDetails,
                    onChanged: (value) {
                      setState(() {
                        _includeEventDetails = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Expense Breakdown'),
                    subtitle: const Text('Include detailed expense categories'),
                    value: _includeExpenseBreakdown,
                    onChanged: (value) {
                      setState(() {
                        _includeExpenseBreakdown = value;
                      });
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Thermal Page Option'),
                    subtitle: const Text(
                      'Enable thermal printer compatible page formatting',
                    ),
                    value: _includeThermalPageOption,
                    onChanged: (value) {
                      setState(() {
                        _includeThermalPageOption = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions Section
            _buildSectionHeader('Actions'),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: const Text('Edit Report Layout'),
                    subtitle: const Text(
                      'Customize the report layout and design',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _editReportLayout(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.print),
                    title: const Text('Thermal Printer Preview'),
                    subtitle: const Text(
                      'Preview and customize thermal printer format',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showThermalPreview(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore_page),
                    title: const Text('Reset to Default Layout'),
                    subtitle: const Text('Restore default layout settings'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _resetToDefaultLayout(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _editReportLayout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HtmlLayoutEditorPage()),
    );
  }

  void _resetToDefaultLayout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default Layout'),
        content: const Text(
          'Are you sure you want to reset the report layout to default settings?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Layout reset to default settings'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showThermalPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ThermalPreviewPage()),
    );
  }

  void _saveSettings() {
    // TODO: Implement settings persistence logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report settings saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }
}

class HtmlLayoutEditorPage extends StatefulWidget {
  const HtmlLayoutEditorPage({super.key});

  @override
  State<HtmlLayoutEditorPage> createState() => _HtmlLayoutEditorPageState();
}

class _HtmlLayoutEditorPageState extends State<HtmlLayoutEditorPage> {
  final TextEditingController _htmlController = TextEditingController();
  bool _isPreviewMode = true;

  // Customer Event Report HTML template matching EXACT export service format
  final String _defaultHtmlTemplate = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Event Report - {{event_name}}</title>
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
        .spent-amount { color: #4CAF50; }
        .remaining-amount { color: #4CAF50; }
        .daily-expense {
            margin: 20px 0;
        }
        .daily-expense-title {
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
        .status-active {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
            background: #4CAF50;
            color: white;
        }
        .status-inactive {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
            background: #000;
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
        <div class="event-title">Sample Wedding Event</div>
        <div class="details-grid">
            <div class="detail-item">
                <span class="detail-label">Event No:</span>
                <span>EVT001</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Customer:</span>
                <span>John & Sarah Smith</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Customer ID:</span>
                <span>CUST001</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Product ID:</span>
                <span>PROD001</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Quantity:</span>
                <span>1</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Status:</span>
                <span class="status-active">active</span>
            </div>
            <div class="detail-item">
                <span class="detail-label">Date:</span>
                <span>15/12/2024</span>
            </div>
        </div>
    </div>

    <div class="financial-summary">
        <div class="summary-title">Financial Summary</div>
        
        <!-- Tax breakdown section (when applicable) -->
        <div class="amount-row">
            <span class="amount-label">Base Amount:</span>
            <span class="amount-value">₹84,745.76</span>
        </div>
        <div class="amount-row">
            <span class="amount-label">Tax (18.0%):</span>
            <span class="amount-value">₹15,254.24</span>
        </div>
        <div class="amount-row">
            <span class="amount-label">Total Amount:</span>
            <span class="amount-value agreed-amount">₹100,000.00</span>
        </div>
        
        <!-- Daily expense breakdown -->
        <div class="daily-expense">
            <div class="daily-expense-title">Expenses Breakdown</div>
            <div class="event-item">
                <span class="event-name">Venue Decoration</span>
                <span class="event-amount">₹25,000.00</span>
            </div>
            <div class="event-item">
                <span class="event-name">Catering Service</span>
                <span class="event-amount">₹35,000.00</span>
            </div>
            <div class="event-item">
                <span class="event-name">Photography</span>
                <span class="event-amount">₹15,000.00</span>
            </div>
            <div class="event-item">
                <span class="event-name">Music & Entertainment</span>
                <span class="event-amount">₹10,000.00</span>
            </div>
        </div>
        
        <div class="divider"></div>
        
        <div class="amount-row">
            <span class="amount-label">Total Spent:</span>
            <span class="amount-value spent-amount">₹85,000.00</span>
        </div>
        
        <div class="amount-row">
            <span class="amount-label">Remaining:</span>
            <span class="amount-value remaining-amount">₹15,000.00</span>
        </div>
    </div>

    <div class="footer">
        Generated on 28/9/2025 at 14:30
    </div>
</body>
</html>
  ''';

  @override
  void initState() {
    super.initState();
    _htmlController.text = _defaultHtmlTemplate;
  }

  @override
  void dispose() {
    _htmlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Layout Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.code : Icons.preview),
            onPressed: () {
              setState(() {
                _isPreviewMode = !_isPreviewMode;
              });
            },
            tooltip: _isPreviewMode ? 'Edit HTML' : 'Preview',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaultTemplate,
            tooltip: 'Reset to Default',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
            tooltip: 'Save Template',
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode Toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _isPreviewMode ? Icons.preview : Icons.code,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _isPreviewMode ? 'Preview Mode' : 'Edit Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!_isPreviewMode)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isPreviewMode = true;
                      });
                    },
                    icon: const Icon(Icons.preview),
                    label: const Text('Preview'),
                  ),
              ],
            ),
          ),

          // Content Area
          Expanded(child: _isPreviewMode ? _buildPreview() : _buildEditor()),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is a preview of the actual Customer Event Report template used in exports. Variables will be replaced with real data.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // HTML Preview (using actual export template style)
            _buildActualHtmlPreviewWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildActualHtmlPreviewWidget() {
    // Force light theme for preview to simulate PDF appearance (white background, dark text)
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          surface: Colors.white,
          onSurface: Colors.black,
          primary: Color(0xFF4CAF50),
          onPrimary: Colors.white,
          outline: Colors.grey.shade300,
        ),
      ),
      child: Builder(
        builder: (context) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header matching actual export template
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                        'BookKeep Accounting',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Customer Event Report',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                // Event Details Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Color(
                            0xFFF8F9FA,
                          ), // Light gray background for content area
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '{{event_name}}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildDetailRow('Event No:', '{{event_no}}'),
                            _buildDetailRow('Customer:', '{{customer_name}}'),
                            _buildDetailRow('Customer ID:', '{{customer_id}}'),
                            _buildDetailRow('Product ID:', '{{product_id}}'),
                            _buildDetailRow('Quantity:', '{{quantity}}'),
                            _buildDetailRow('Status:', '{{status}}'),
                            _buildDetailRow('Date:', '{{event_date}}'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Financial Summary - Matching Export Service Exactly
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Color(0xFF4CAF50),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Financial Summary',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Tax breakdown section (when applicable)
                            _buildAmountRow(
                              'Base Amount:',
                              '₹84,745.76',
                              Colors.black,
                            ),
                            _buildAmountRow(
                              'Tax (18.0%):',
                              '₹15,254.24',
                              Colors.black,
                            ),
                            _buildAmountRow(
                              'Total Amount:',
                              '₹100,000.00',
                              Color(0xFF2196F3),
                            ),

                            const SizedBox(height: 20),

                            // Daily expense breakdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black),
                                    ),
                                  ),
                                  child: Text(
                                    'Expenses Breakdown',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _buildExpenseItem(
                                  'Venue Decoration',
                                  '₹25,000.00',
                                ),
                                _buildExpenseItem(
                                  'Catering Service',
                                  '₹35,000.00',
                                ),
                                _buildExpenseItem('Photography', '₹15,000.00'),
                                _buildExpenseItem(
                                  'Music & Entertainment',
                                  '₹10,000.00',
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Divider matching export service
                            Container(
                              height: 2,
                              width: double.infinity,
                              color: Color(0xFF4CAF50),
                            ),

                            const SizedBox(height: 20),

                            _buildAmountRow(
                              'Total Spent:',
                              '₹85,000.00',
                              Color(0xFF4CAF50),
                            ),
                            _buildAmountRow(
                              'Remaining:',
                              '₹15,000.00',
                              Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Footer matching export service
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.black)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '{{expense_items}}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black, // Force black text
                              ),
                            ),
                            Text(
                              '{{expense_amounts}}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black, // Force black text for labels
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black,
            ), // Force black text for values
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black, // Force black text for better readability
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String eventName, String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: Color(0xFF4CAF50), width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            eventName,
            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Editor Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit the HTML template below. Use variables like {{date}}, {{customer_rows}}, {{total_revenue}} for dynamic content.',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // HTML Editor
          Expanded(
            child: TextField(
              controller: _htmlController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Enter your HTML template here...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetToDefaultTemplate() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Template'),
        content: const Text(
          'Are you sure you want to reset the HTML template to default? This will overwrite your current changes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _htmlController.text = _defaultHtmlTemplate;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Template reset to default'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _saveTemplate() {
    // TODO: Implement template saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('HTML template saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ThermalPreviewPage extends StatefulWidget {
  const ThermalPreviewPage({super.key});

  @override
  State<ThermalPreviewPage> createState() => _ThermalPreviewPageState();
}

class _ThermalPreviewPageState extends State<ThermalPreviewPage> {
  bool _isEditMode = false;
  final TextEditingController _thermalTemplateController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _thermalTemplateController.text = _getDefaultThermalTemplate();
  }

  @override
  void dispose() {
    _thermalTemplateController.dispose();
    super.dispose();
  }

  String _getDefaultThermalTemplate() {
    return '''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Thermal Receipt - Sample Wedding Event</title>
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

    <div class="event-title">Sample Wedding Event</div>
    
    <div class="row">
        <span class="label">Event No:</span>
        <span class="value">EVT001</span>
    </div>
    
    <div class="row">
        <span class="label">Customer:</span>
        <span class="value">John & Sarah Smith</span>
    </div>
    
    <div class="row">
        <span class="label">Cust ID:</span>
        <span class="value">CUST001</span>
    </div>
    
    <div class="row">
        <span class="label">Quantity:</span>
        <span class="value">1</span>
    </div>
    
    <div class="status">STATUS: ACTIVE</div>
    
    <div class="row">
        <span class="label">Date:</span>
        <span class="value">28/9/2025</span>
    </div>

    <div class="divider"></div>
    
    <div class="row">
        <span class="label">Base Amt:</span>
        <span class="value">₹84,745.76</span>
    </div>
    <div class="row">
        <span class="label">Tax (18.0%):</span>
        <span class="value">₹15,254.24</span>
    </div>
    <div class="row">
        <span class="label">Total Amt:</span>
        <span class="value">₹100,000.00</span>
    </div>

    <div class="divider"></div>
    <div style="text-align: center; font-weight: bold; margin: 5px 0;">DAILY EXPENSE</div>
    
    <div class="daily-event-row">
        <span class="event-name">Venue Decoration</span>
        <span class="event-amount">₹25,000.00</span>
    </div>
    <div class="daily-event-row">
        <span class="event-name">Catering Service</span>
        <span class="event-amount">₹35,000.00</span>
    </div>
    <div class="daily-event-row">
        <span class="event-name">Photography</span>
        <span class="event-amount">₹15,000.00</span>
    </div>
    <div class="daily-event-row">
        <span class="event-name">Music & Entertainment</span>
        <span class="event-amount">₹10,000.00</span>
    </div>

    <div class="total-row">
        <div class="row">
            <span class="label">Total Spent:</span>
            <span class="value">₹85,000.00</span>
        </div>
        <div class="row">
            <span class="label">Remaining:</span>
            <span class="value">₹15,000.00</span>
        </div>
    </div>

    <div class="footer">
        Generated: 28/9/2025<br>
        14:30
    </div>
</body>
</html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Preview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.visibility : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            tooltip: _isEditMode ? 'Preview Mode' : 'Edit Mode',
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: _resetToDefaultThermal,
            tooltip: 'Reset to Default',
          ),
        ],
      ),
      body: _isEditMode ? _buildEditor() : _buildPreview(),
      floatingActionButton: _isEditMode
          ? FloatingActionButton(
              onPressed: _saveThermalTemplate,
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Edit the thermal printer template. Use placeholders like {{event_name}} for dynamic content.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _thermalTemplateController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter thermal printer template...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          width: 300, // Typical thermal printer width (80mm ≈ 300px)
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400, width: 2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.print, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Thermal Printer (80mm)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Render thermal receipt layout
              _buildThermalReceiptPreview(),
            ],
          ),
        ),
      ),
    );
  }

  // Build actual thermal receipt layout preview
  Widget _buildThermalReceiptPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Text(
          'BOOKKEEP ACCOUNTING',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          'Customer Event Report',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.black), // Divider
        const SizedBox(height: 8),

        // Event Title
        Text(
          'Sample Wedding Event',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),

        // Event Details
        _buildThermalRow('Event No:', 'EVT001'),
        _buildThermalRow('Customer:', 'John & Sarah Smith'),
        _buildThermalRow('Cust ID:', 'CUST001'),
        _buildThermalRow('Quantity:', '1'),
        const SizedBox(height: 4),

        Text(
          'STATUS: ACTIVE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),

        _buildThermalRow('Date:', '28/9/2025'),
        const SizedBox(height: 8),

        // Dashed divider
        Row(
          children: List.generate(
            30,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1),
                height: 1,
                color: index % 2 == 0 ? Colors.black : Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Financial Details
        _buildThermalRow('Base Amt:', '₹84,745.76'),
        _buildThermalRow('Tax (18.0%):', '₹15,254.24'),
        _buildThermalRow('Total Amt:', '₹100,000.00'),
        const SizedBox(height: 8),

        // Dashed divider
        Row(
          children: List.generate(
            30,
            (index) => Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1),
                height: 1,
                color: index % 2 == 0 ? Colors.black : Colors.transparent,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Daily Expense Header
        Text(
          'DAILY EXPENSE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),

        // Expense Items
        _buildThermalExpenseRow('Venue Decoration', '₹25,000.00'),
        _buildThermalExpenseRow('Catering Service', '₹35,000.00'),
        _buildThermalExpenseRow('Photography', '₹15,000.00'),
        _buildThermalExpenseRow('Music & Entertainment', '₹10,000.00'),
        const SizedBox(height: 8),

        // Total Section with borders
        Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.black, width: 1),
              bottom: BorderSide(color: Colors.black, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildThermalRow('Total Spent:', '₹85,000.00', bold: true),
              _buildThermalRow('Remaining:', '₹15,000.00', bold: true),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Container(height: 1, color: Colors.black), // Divider
        const SizedBox(height: 4),

        // Footer
        Text(
          'Generated: 28/9/2025\n14:30',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Helper method to build thermal receipt rows
  Widget _buildThermalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build expense rows (smaller font for names)
  Widget _buildThermalExpenseRow(String name, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 7,
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              amount,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetToDefaultThermal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Thermal Template'),
        content: const Text(
          'Are you sure you want to reset the thermal printer template to default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _thermalTemplateController.text = _getDefaultThermalTemplate();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thermal template reset to default'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _saveThermalTemplate() {
    // TODO: Implement thermal template saving logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thermal template saved successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
