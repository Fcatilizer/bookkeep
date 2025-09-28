import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/customer_event.dart';
import '../services/event_service.dart';
import '../services/customer_event_service.dart';
import '../services/csv_export_service.dart';
import '../helpers/daily_expense_dialog.dart';

enum ViewMode { card, table }

class DailyExpensePage extends StatefulWidget {
  const DailyExpensePage({super.key});

  @override
  State<DailyExpensePage> createState() => _DailyExpensePageState();
}

class _DailyExpensePageState extends State<DailyExpensePage> {
  final EventService _eventService = EventService();
  final CustomerEventService _customerEventService = CustomerEventService();
  List<Event> _expenses = [];
  List<Event> _filteredExpenses = [];
  Map<String, List<Event>> _groupedExpenses = {};
  Map<String, double> _customerTotals = {};
  Map<String, CustomerEvent> _customerEvents = {};
  bool _isLoading = true;
  ViewMode _currentViewMode = ViewMode.card;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'date'; // date, customer, amount, expenseType
  bool _sortAscending = false; // Default to newest first for expenses
  String _filterBy = 'all'; // all, customer, expenseType, date

  // ScrollControllers for table view
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerEvents() async {
    try {
      final customerEventsList = await _customerEventService
          .getAllCustomerEvents();
      _customerEvents.clear();
      for (final event in customerEventsList) {
        _customerEvents[event.eventNo] = event;
      }
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await _eventService.getAllEvents();
      await _loadCustomerEvents();
      _groupExpensesByCustomer(expenses);
      setState(() {
        _expenses = expenses;
        _filteredExpenses = List.from(expenses);
        _sortExpenses();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading expenses: $e')));
      }
    }
  }

  void _groupExpensesByCustomer(List<Event> expenses) {
    _groupedExpenses.clear();
    _customerTotals.clear();

    for (final expense in expenses) {
      final custId = expense.custId;

      if (!_groupedExpenses.containsKey(custId)) {
        _groupedExpenses[custId] = [];
        _customerTotals[custId] = 0.0;
      }

      _groupedExpenses[custId]!.add(expense);
      _customerTotals[custId] = _customerTotals[custId]! + expense.amount;
    }
  }

  void _filterExpenses(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredExpenses = List.from(_expenses);
      } else {
        _filteredExpenses = _expenses.where((expense) {
          final searchLower = searchTerm.toLowerCase();

          switch (_filterBy) {
            case 'customer':
              return expense.custId.toLowerCase().contains(searchLower) ||
                  expense.customerName.toLowerCase().contains(searchLower);
            case 'expenseType':
              return expense.expenseType.toLowerCase().contains(searchLower);
            case 'all':
            default:
              return expense.custId.toLowerCase().contains(searchLower) ||
                  expense.customerName.toLowerCase().contains(searchLower) ||
                  expense.productId.toLowerCase().contains(searchLower) ||
                  expense.expenseType.toLowerCase().contains(searchLower) ||
                  expense.expenseName.toLowerCase().contains(searchLower) ||
                  (expense.eventDate?.toString().contains(searchLower) ??
                      false);
          }
        }).toList();
      }
      _sortExpenses();
      _groupExpensesByCustomer(_filteredExpenses);
    });
  }

  void _sortExpenses() {
    _filteredExpenses.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          final dateA = a.eventDate ?? DateTime(1900);
          final dateB = b.eventDate ?? DateTime(1900);
          comparison = dateA.compareTo(dateB);
          break;
        case 'customer':
          comparison = a.custId.compareTo(b.custId);
          break;
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'expenseType':
          comparison = a.expenseType.compareTo(b.expenseType);
          break;
        default:
          final dateA = a.eventDate ?? DateTime(1900);
          final dateB = b.eventDate ?? DateTime(1900);
          comparison = dateA.compareTo(dateB);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _changeFilterBy(String newFilter) {
    setState(() {
      _filterBy = newFilter;
      _filterExpenses(_searchController.text);
    });
  }

  void _changeSortOrder(String newSort) {
    setState(() {
      if (_sortBy == newSort) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = newSort;
        _sortAscending = newSort == 'date'
            ? false
            : true; // Expenses default to newest first
      }
      _sortExpenses();
      _groupExpensesByCustomer(_filteredExpenses);
    });
  }

  Future<void> _exportToCSV() async {
    try {
      final filePath = await CsvExportService.exportEventsToCSV(_expenses);
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

  Widget _buildExpenseCard(Event expense) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expense.expenseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        await DailyExpenseDialog.showEditExpenseDialog(
                          context,
                          expense,
                        );
                        _loadExpenses();
                      },
                      icon: const Icon(Icons.edit),
                      iconSize: 20,
                      tooltip: 'Edit Expense',
                    ),
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(expense),
                      icon: const Icon(Icons.delete),
                      iconSize: 20,
                      color: Colors.red,
                      tooltip: 'Delete Expense',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.confirmation_number,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Expense No: ${expense.eventNo}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Customer: ${expense.customerName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Customer Event: ${expense.customerEventNo}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (expense.productId.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Product: ${expense.productId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Type: ${expense.expenseType}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (expense.eventDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Date: ${expense.eventDate!.day}/${expense.eventDate!.month}/${expense.eventDate!.year}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Event expense) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete the expense "${expense.expenseName}"?\n\nThis action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteExpense(expense);
    }
  }

  Future<void> _deleteExpense(Event expense) async {
    try {
      final success = await _eventService.deleteEvent(expense.eventNo);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense "${expense.expenseName}" deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadExpenses(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete expense'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    icon: Icon(Icons.download, size: 18),
                    label: Text('Export CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_currentViewMode == ViewMode.table)
                  const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadExpenses,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await DailyExpenseDialog.showAddExpenseDialog(context);
                    _loadExpenses();
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('Add Expense'),
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
                    labelText: 'Search daily expenses...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterExpenses('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onChanged: _filterExpenses,
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
                              _buildFilterChip('Customer', 'customer'),
                              _buildFilterChip('Expense Type', 'expenseType'),
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
                              _buildSortChip('Date', 'date'),
                              _buildSortChip('Customer', 'customer'),
                              _buildSortChip('Amount', 'amount'),
                              _buildSortChip('Expense Type', 'expenseType'),
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
          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExpenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses found.\nTap + to add your first expense!',
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
                : _currentViewMode == ViewMode.table
                ? _buildTableView()
                : _buildCardView(),
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
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Expense No',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Expense Name',
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
                    'Customer Event',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Expense Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Amount (₹)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: _filteredExpenses.map((event) {
                return DataRow(
                  cells: [
                    DataCell(Text(event.eventNo)),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          event.eventName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          event.customerName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          _customerEvents[event.customerEventNo]?.eventName ??
                              'N/A',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          event.productId.isEmpty ? 'N/A' : event.productId,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 100,
                        child: Text(
                          event.expenseType,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        event.amount.toStringAsFixed(2),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        event.eventDate != null
                            ? '${event.eventDate!.day}/${event.eventDate!.month}/${event.eventDate!.year}'
                            : 'N/A',
                        style: TextStyle(fontSize: 12),
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

  Widget _buildCardView() {
    return RefreshIndicator(
      onRefresh: _loadExpenses,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _groupedExpenses.entries.map((entry) {
          final custId = entry.key;
          final customerExpenses = entry.value;
          final customerName = customerExpenses.isNotEmpty
              ? customerExpenses.first.customerName
              : 'Unknown Customer';

          // Get customer event name if available
          final customerEventNo = customerExpenses.isNotEmpty
              ? customerExpenses.first.customerEventNo
              : null;
          final customerEventName =
              customerEventNo != null &&
                  _customerEvents.containsKey(customerEventNo)
              ? _customerEvents[customerEventNo]!.eventName
              : null;

          // Create display title with customer name and event name
          final displayTitle = customerEventName != null
              ? '$customerName - $customerEventName'
              : customerName;

          final total = _customerTotals[custId] ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text(
                displayTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Customer ID: $custId',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              children: customerExpenses
                  .map((expense) => _buildExpenseCard(expense))
                  .toList(),
            ),
          );
        }).toList(),
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
