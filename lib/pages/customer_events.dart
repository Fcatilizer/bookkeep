import 'package:flutter/material.dart';
import '../models/customer_event.dart';
import '../services/customer_event_service.dart';
import '../services/csv_export_service.dart';
import '../helpers/customer_event_dialog.dart';
import '../helpers/event_dialog.dart';
import '../helpers/export_preview_dialog.dart';

enum ViewMode { card, table }

class CustomerEventsPage extends StatefulWidget {
  const CustomerEventsPage({super.key});

  @override
  State<CustomerEventsPage> createState() => _CustomerEventsPageState();
}

class _CustomerEventsPageState extends State<CustomerEventsPage> {
  final CustomerEventService _customerEventService = CustomerEventService();
  List<Map<String, dynamic>> _eventsWithTotals = [];
  List<Map<String, dynamic>> _filteredEventsWithTotals = [];
  bool _isLoading = true;
  ViewMode _currentViewMode = ViewMode.card;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _sortBy =
      'customerName'; // customerName, agreedAmount, dailyTotal, eventDate
  bool _sortAscending = true;
  String _filterBy = 'all'; // all, ongoing, completed, overBudget

  // ScrollControllers for table view
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCustomerEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerEvents() async {
    setState(() => _isLoading = true);
    try {
      final eventsWithTotals = await _customerEventService
          .getCustomerEventsWithTotals();
      setState(() {
        _eventsWithTotals = eventsWithTotals;
        _filteredEventsWithTotals = List.from(eventsWithTotals);
        _sortEvents();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customer events: $e')),
        );
      }
    }
  }

  void _filterEvents(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredEventsWithTotals = List.from(_eventsWithTotals);
      } else {
        _filteredEventsWithTotals = _eventsWithTotals.where((eventData) {
          final event = CustomerEvent.fromMap(eventData);
          final searchLower = searchTerm.toLowerCase();

          switch (_filterBy) {
            case 'customerName':
              return event.customerName.toLowerCase().contains(searchLower);
            case 'custId':
              return event.custId.toLowerCase().contains(searchLower);
            case 'all':
            default:
              return event.customerName.toLowerCase().contains(searchLower) ||
                  event.custId.toLowerCase().contains(searchLower) ||
                  event.eventName.toLowerCase().contains(searchLower);
          }
        }).toList();
      }
      _applyFilter();
      _sortEvents();
    });
  }

  void _applyFilter() {
    if (_filterBy == 'all') return;

    _filteredEventsWithTotals = _filteredEventsWithTotals.where((eventData) {
      final event = CustomerEvent.fromMap(eventData);
      final dailyTotalRaw = eventData['daily_total'];
      final dailyTotal = (dailyTotalRaw is int)
          ? dailyTotalRaw.toDouble()
          : (dailyTotalRaw as double? ?? 0.0);

      switch (_filterBy) {
        case 'ongoing':
          return dailyTotal < event.agreedAmount;
        case 'completed':
          return dailyTotal >= event.agreedAmount &&
              dailyTotal <= event.agreedAmount;
        case 'overBudget':
          return dailyTotal > event.agreedAmount;
        default:
          return true;
      }
    }).toList();
  }

  void _sortEvents() {
    _filteredEventsWithTotals.sort((a, b) {
      final eventA = CustomerEvent.fromMap(a);
      final eventB = CustomerEvent.fromMap(b);

      int comparison = 0;
      switch (_sortBy) {
        case 'customerName':
          comparison = eventA.customerName.compareTo(eventB.customerName);
          break;
        case 'agreedAmount':
          comparison = eventA.agreedAmount.compareTo(eventB.agreedAmount);
          break;
        case 'dailyTotal':
          final dailyTotalA = (a['daily_total'] is int)
              ? (a['daily_total'] as int).toDouble()
              : (a['daily_total'] as double? ?? 0.0);
          final dailyTotalB = (b['daily_total'] is int)
              ? (b['daily_total'] as int).toDouble()
              : (b['daily_total'] as double? ?? 0.0);
          comparison = dailyTotalA.compareTo(dailyTotalB);
          break;
        case 'eventDate':
          comparison = (eventA.eventDate ?? DateTime(1900)).compareTo(
            eventB.eventDate ?? DateTime(1900),
          );
          break;
        default:
          comparison = eventA.customerName.compareTo(eventB.customerName);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _changeFilterBy(String newFilter) {
    setState(() {
      _filterBy = newFilter;
      _filterEvents(_searchController.text);
    });
  }

  void _changeSortOrder(String newSort) {
    setState(() {
      if (_sortBy == newSort) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSort;
        _sortAscending = true;
      }
      _sortEvents();
    });
  }

  Future<void> _exportToCSV() async {
    try {
      // Convert the eventsWithTotals data to CustomerEvent objects for export
      final customerEvents = _eventsWithTotals.map((eventData) {
        return CustomerEvent.fromMap(eventData);
      }).toList();

      final filePath = await CsvExportService.exportCustomerEventsToCSV(
        customerEvents,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV exported successfully to: $filePath'),
            duration: Duration(seconds: 4),
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEventCard(Map<String, dynamic> eventData) {
    final event = CustomerEvent.fromMap(eventData);
    // Handle potential int/double conversion issue from database
    final dailyTotalRaw = eventData['daily_total'];
    final dailyTotal = (dailyTotalRaw is int)
        ? dailyTotalRaw.toDouble()
        : (dailyTotalRaw as double? ?? 0.0);
    final remainingAmount = event.agreedAmount - dailyTotal;
    final isOverBudget = dailyTotal > event.agreedAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: event.status == 'active'
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            event.status == 'active' ? Icons.work : Icons.work_off,
            color: event.status == 'active'
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          event.eventName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event No: ${event.eventNo}'),
            Text('Customer: ${event.customerName}'),
            Text('Quantity: ${event.quantity}'),
            Text('Status: ${event.status.toUpperCase()}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Agreed: ₹${event.agreedAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Spent: ₹${dailyTotal.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOverBudget ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Remaining: ₹${remainingAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOverBudget
                    ? Colors.red
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Details Section
                Text(
                  'Event Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Event Date:'),
                          Text(
                            event.eventDate?.toLocal().toString().split(
                                  ' ',
                                )[0] ??
                                'Not set',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Expected Finish:'),
                          Text(
                            event.expectedFinishingDate
                                    ?.toLocal()
                                    .toString()
                                    .split(' ')[0] ??
                                'Not set',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: event.expectedFinishingDate != null
                                  ? (DateTime.now().isAfter(
                                              event.expectedFinishingDate!,
                                            ) &&
                                            event.status == 'active'
                                        ? Colors
                                              .red // Overdue
                                        : Colors.green) // On time
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Financial Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverBudget
                        ? Colors.red.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOverBudget ? Colors.red : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Agreed Amount:'),
                          Text(
                            '₹${event.agreedAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Daily events breakdown
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _customerEventService
                            .getDailyEventsForCustomerEvent(event.eventNo),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Text(
                              'Error loading daily activity: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          final dailyEvents = snapshot.data ?? [];

                          if (dailyEvents.isEmpty) {
                            return const Text(
                              'No daily activity recorded yet',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Daily Activity:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              ...dailyEvents.map((dailyEvent) {
                                final amount = (dailyEvent['Amount'] is int)
                                    ? (dailyEvent['Amount'] as int).toDouble()
                                    : (dailyEvent['Amount'] as double? ?? 0.0);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '• ${dailyEvent['Event_Name'] ?? 'Unnamed Event'}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      Text(
                                        '₹${amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: isOverBudget
                                              ? Colors.red
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 4),
                            ],
                          );
                        },
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Spent:'),
                          Text(
                            '₹${dailyTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isOverBudget ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isOverBudget ? 'Over Budget:' : 'Remaining:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isOverBudget ? Colors.red : Colors.green,
                            ),
                          ),
                          Text(
                            '₹${remainingAmount.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isOverBudget ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Project Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text('Customer ID: ${event.custId}'),
                Text('Product ID: ${event.productId}'),
                Text('Quantity: ${event.quantity}'),
                if (event.eventDate != null)
                  Text(
                    'Date: ${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}',
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        CustomerEventDialog.showEditCustomerEventDialog(
                          context,
                          event,
                        );
                        // Refresh the list after dialog is dismissed
                        await Future.delayed(const Duration(milliseconds: 500));
                        _loadCustomerEvents();
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Event'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Open the Event Dialog to add a daily event
                        EventDialog.showAddEventDialog(context);
                        // Refresh the list after dialog is dismissed
                        await Future.delayed(const Duration(milliseconds: 500));
                        _loadCustomerEvents();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Daily Event'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ExportPreviewDialog.showExportPreviewDialog(
                          context,
                          event,
                        );
                      },
                      icon: const Icon(Icons.file_download),
                      label: const Text('Export Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView() {
    return Scrollbar(
      controller: _horizontalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: _verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 48,
              dataRowHeight: 48,
              columns: const [
                DataColumn(
                  label: Text(
                    'Event No',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Event Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Customer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Product ID',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Event Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Expected Finish',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Agreed Amount',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total Daily',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Remaining',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _filteredEventsWithTotals.map((eventData) {
                final event = CustomerEvent.fromMap(eventData);
                final dailyTotalRaw = eventData['daily_total'];
                final dailyTotal = (dailyTotalRaw is int)
                    ? dailyTotalRaw.toDouble()
                    : (dailyTotalRaw as double? ?? 0.0);

                final remainingAmount = event.agreedAmount - dailyTotal;
                final isOverBudget = dailyTotal > event.agreedAmount;

                // Determine status color
                Color statusColor;
                switch (event.status.toLowerCase()) {
                  case 'active':
                    statusColor = Colors.green;
                    break;
                  case 'completed':
                    statusColor = Colors.blue;
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    break;
                  default:
                    statusColor = Colors.grey;
                }

                return DataRow(
                  cells: [
                    DataCell(Text(event.eventNo)),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          event.eventName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          event.customerName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(event.productId)),
                    DataCell(Text(event.quantity.toString())),
                    DataCell(
                      Text(
                        event.eventDate?.toLocal().toString().split(' ')[0] ??
                            'N/A',
                      ),
                    ),
                    DataCell(
                      Text(
                        event.expectedFinishingDate?.toLocal().toString().split(
                              ' ',
                            )[0] ??
                            'N/A',
                      ),
                    ),
                    DataCell(Text('₹${event.agreedAmount.toStringAsFixed(2)}')),
                    DataCell(
                      Text(
                        '₹${dailyTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: dailyTotal > event.agreedAmount
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '₹${remainingAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isOverBudget
                              ? Colors
                                    .red // Loss (over budget)
                              : remainingAmount > 0
                              ? Colors
                                    .green // Profit (under budget)
                              : Colors.white, // Normal (exact budget)
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          event.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ), // closes DataTable
          ), // closes inner SingleChildScrollView
        ), // closes inner Scrollbar
      ), // closes outer SingleChildScrollView
    ); // closes outer Scrollbar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // View Mode and Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'View:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                // View mode toggle buttons
                ToggleButtons(
                  children: [
                    Icon(Icons.view_list, size: 18),
                    Icon(Icons.table_chart, size: 18),
                  ],
                  isSelected: [
                    _currentViewMode == ViewMode.card,
                    _currentViewMode == ViewMode.table,
                  ],
                  onPressed: (int index) {
                    setState(() {
                      _currentViewMode = index == 0
                          ? ViewMode.card
                          : ViewMode.table;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: BoxConstraints(minWidth: 35, minHeight: 35),
                ),
                const Spacer(),
                if (_currentViewMode == ViewMode.table)
                  ElevatedButton.icon(
                    onPressed: _exportToCSV,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_currentViewMode == ViewMode.table)
                  const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadCustomerEvents,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    CustomerEventDialog.showAddCustomerEventDialog(context);
                    // Refresh the list after dialog is dismissed
                    await Future.delayed(const Duration(milliseconds: 500));
                    _loadCustomerEvents();
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add Customer Event'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6FAADB),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Search and Filter Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search customer events...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterEvents('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: _filterEvents,
                ),
                const SizedBox(height: 16),
                // Filter and Sort Controls
                Row(
                  children: [
                    // Filter dropdown
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by:',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildFilterChip('All', 'all'),
                              _buildFilterChip('Ongoing', 'ongoing'),
                              _buildFilterChip('Completed', 'completed'),
                              _buildFilterChip('Over Budget', 'overBudget'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort controls
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sort by:',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildSortChip('Customer', 'customerName'),
                              _buildSortChip('Amount', 'agreedAmount'),
                              _buildSortChip('Total', 'dailyTotal'),
                              _buildSortChip('Date', 'eventDate'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEventsWithTotals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No customer events found.\nTap + to add your first customer event!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : _currentViewMode == ViewMode.card
                ? RefreshIndicator(
                    onRefresh: _loadCustomerEvents,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredEventsWithTotals.length,
                      itemBuilder: (context, index) {
                        return _buildEventCard(
                          _filteredEventsWithTotals[index],
                        );
                      },
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCustomerEvents,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildTableView(),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "customer_events_fab",
        onPressed: () async {
          CustomerEventDialog.showAddCustomerEventDialog(context);
          // Refresh the list after dialog is dismissed
          await Future.delayed(const Duration(milliseconds: 500));
          _loadCustomerEvents();
        },
        tooltip: 'Add Customer Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => _changeFilterBy(value),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      onPressed: () => _changeSortOrder(value),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
