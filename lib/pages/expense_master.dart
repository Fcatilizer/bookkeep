// 📚 BookKeep - Expense Master Page
//
// This file contains the main expense and payment management interface.
// It provides comprehensive functionality for:
// - Expense type management with CRUD operations
// - Payment tracking with advanced filtering and search
// - Data visualization with table and card views
// - Export capabilities for CSV generation
// - Responsive design for mobile and desktop platforms
//
// Author: Ashish Gaurav (@Fcatilizer)
// Created: 2025
// Last Updated: September 24, 2025

import 'package:flutter/material.dart';

// Data Models
import '../models/expense_type.dart';
import '../models/payment_mode.dart';
import '../models/payment.dart';
import '../models/payment_summary.dart';

// Business Logic Services
import '../services/expense_type_service.dart';
import '../services/payment_mode_service.dart';
import '../services/payment_service.dart';
import '../services/payment_summary_service.dart';
import '../services/customer_event_service.dart';
import '../services/csv_export_service.dart';

// UI Helper Dialogs
import '../helpers/payment_dialog.dart';
import '../helpers/expense_type_dialog.dart';

// Standardized UI Components
import '../widgets/standardized_page_header.dart';
import '../widgets/standardized_search_filter.dart';
import '../widgets/standardized_common_widgets.dart';

/// ExpenseMasterPage - Main page for expense and payment management
///
/// This page provides a comprehensive interface for managing:
/// - Expense types and categories
/// - Payment records with advanced filtering
/// - Data export and visualization
///
/// Features:
/// - Tabbed interface for organized data management
/// - Advanced search and filtering capabilities
/// - Responsive design for multiple screen sizes
/// - Real-time data updates and synchronization
class ExpenseMasterPage extends StatefulWidget {
  const ExpenseMasterPage({Key? key}) : super(key: key);

  @override
  State<ExpenseMasterPage> createState() => _ExpenseMasterPageState();
}

/// State class for ExpenseMasterPage
///
/// Manages the state for expense types, payment modes, and payment records.
/// Implements comprehensive filtering, searching, and data visualization features.
class _ExpenseMasterPageState extends State<ExpenseMasterPage>
    with SingleTickerProviderStateMixin {
  // ══════════════════════════════════════════════════════════════
  // UI Controllers & Navigation
  // ══════════════════════════════════════════════════════════════

  /// Tab controller for managing expense types and payments tabs
  late TabController _tabController;

  /// Text controllers for search functionality across different sections
  final TextEditingController _expenseSearchController =
      TextEditingController();
  final TextEditingController _paymentSearchController =
      TextEditingController();
  final TextEditingController _paymentsSearchController =
      TextEditingController();

  /// Scroll controllers for table view with proper disposal management
  final ScrollController _tableHorizontalController = ScrollController();
  final ScrollController _tableVerticalController = ScrollController();

  // ══════════════════════════════════════════════════════════════
  // Business Logic Services
  // ══════════════════════════════════════════════════════════════

  /// Services for data operations and business logic
  final ExpenseTypeService _expenseTypeService = ExpenseTypeService();
  final PaymentModeService _paymentModeService = PaymentModeService();
  final PaymentService _paymentService = PaymentService();

  // ══════════════════════════════════════════════════════════════
  // Expense Types State Management
  // ══════════════════════════════════════════════════════════════

  /// Raw expense types data from database
  List<ExpenseType> _expenseTypes = [];

  /// Filtered expense types based on search and filter criteria
  List<ExpenseType> _filteredExpenseTypes = [];

  /// Current search query for expense types
  String _expenseSearchQuery = '';

  /// Current filter selection (All, Active, Inactive)
  String _expenseFilter = 'All';

  /// Current sort selection (Name, Category, Date)
  String _expenseSort = 'Name';

  // ══════════════════════════════════════════════════════════════
  // Payment Modes State Management
  // ══════════════════════════════════════════════════════════════

  /// Raw payment modes data from database
  List<PaymentMode> _paymentModes = [];

  /// Filtered payment modes based on search and filter criteria
  // Note: Currently unused as payment mode management is handled separately
  // ignore: unused_field
  List<PaymentMode> _filteredPaymentModes = [];

  /// Current search query for payment modes
  String _paymentSearchQuery = '';

  /// Current filter selection (All, Active, Inactive)
  String _paymentFilter = 'All';

  /// Current sort selection (Name, Type)
  String _paymentSort = 'Name';

  // ══════════════════════════════════════════════════════════════
  // Payments State Management
  // ══════════════════════════════════════════════════════════════

  /// Raw payments data from database
  List<Payment> _payments = [];

  /// Filtered payments based on all active filter criteria
  List<Payment> _filteredPayments = [];

  /// Aggregated payment summaries for grouped view
  List<PaymentSummary> _paymentSummaries = [];

  /// Current search query for payments (searches across multiple fields)
  String _paymentsSearchQuery = '';

  /// Payment status filter (All, Pending, Partial, Full)
  String _paymentsFilter = 'All';

  /// Sort option (Date, Amount, Status, PaymentMode)
  String _paymentsSort = 'Date';

  /// Payment method filter (All, Cash, Cheque, UPI, etc.)
  String _paymentsPaymentModeFilter = 'All';

  /// Date range filtering
  DateTime? _paymentsFromDate;
  DateTime? _paymentsToDate;

  // ══════════════════════════════════════════════════════════════
  // UI State Management
  // ══════════════════════════════════════════════════════════════

  /// Toggle between grouped summary view and individual payment view
  bool _showGroupedView = true;

  /// Toggle between table view and card view for payments
  bool _showTableView = false;

  /// Toggle for expandable filter section (collapsed by default)
  bool _isFiltersExpanded = false;

  /// Loading state indicator
  bool _isLoading = true;

  // ══════════════════════════════════════════════════════════════
  // Widget Lifecycle Methods
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    // Properly dispose of all controllers to prevent memory leaks
    _tabController.dispose();
    _expenseSearchController.dispose();
    _paymentSearchController.dispose();
    _paymentsSearchController.dispose();
    _tableHorizontalController.dispose();
    _tableVerticalController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  // Data Loading & Management Methods
  // ══════════════════════════════════════════════════════════════

  /// Load all data from services in parallel for better performance
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _expenseTypeService.getAllExpenseTypes(),
        _paymentModeService.getAllPaymentModes(),
        _paymentService.getAllPayments(),
      ]);

      setState(() {
        _expenseTypes = results[0] as List<ExpenseType>;
        _paymentModes = results[1] as List<PaymentMode>;
        _payments = results[2] as List<Payment>;
        _applyExpenseFiltersAndSort();
        _applyPaymentFiltersAndSort();
        _applyPaymentsFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Expense Types Management Methods
  // ══════════════════════════════════════════════════════════════

  /// Apply current filters and sorting to expense types
  /// Combines search query, status filter, and sort criteria
  void _applyExpenseFiltersAndSort() {
    List<ExpenseType> filtered = _expenseTypes;

    // Apply search filter
    if (_expenseSearchQuery.isNotEmpty) {
      filtered = filtered.where((expense) {
        return expense.expenseTypeName.toLowerCase().contains(
              _expenseSearchQuery.toLowerCase(),
            ) ||
            expense.category.toLowerCase().contains(
              _expenseSearchQuery.toLowerCase(),
            ) ||
            expense.expenseTypeId.toLowerCase().contains(
              _expenseSearchQuery.toLowerCase(),
            ) ||
            (expense.description?.toLowerCase().contains(
                  _expenseSearchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Apply status filter
    switch (_expenseFilter) {
      case 'Active':
        filtered = filtered.where((expense) => expense.isActive).toList();
        break;
      case 'Inactive':
        filtered = filtered.where((expense) => !expense.isActive).toList();
        break;
      // 'All' shows everything
    }

    // Apply sorting
    switch (_expenseSort) {
      case 'Name':
        filtered.sort((a, b) => a.expenseTypeName.compareTo(b.expenseTypeName));
        break;
      case 'Category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
      case 'Date':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _filteredExpenseTypes = filtered;
    });
  }

  void _onExpenseSearchChanged(String query) {
    setState(() {
      _expenseSearchQuery = query;
    });
    _applyExpenseFiltersAndSort();
  }

  // Payment Modes Methods
  // ══════════════════════════════════════════════════════════════
  // Payment Modes Management Methods
  // ══════════════════════════════════════════════════════════════

  /// Apply current filters and sorting to payment modes
  /// Combines search query, status filter, and sort criteria
  void _applyPaymentFiltersAndSort() {
    List<PaymentMode> filtered = _paymentModes;

    // Apply search filter
    if (_paymentSearchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        return payment.paymentModeName.toLowerCase().contains(
              _paymentSearchQuery.toLowerCase(),
            ) ||
            payment.type.toLowerCase().contains(
              _paymentSearchQuery.toLowerCase(),
            ) ||
            payment.paymentModeId.toLowerCase().contains(
              _paymentSearchQuery.toLowerCase(),
            ) ||
            (payment.description?.toLowerCase().contains(
                  _paymentSearchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    // Apply status filter
    switch (_paymentFilter) {
      case 'Active':
        filtered = filtered.where((payment) => payment.isActive).toList();
        break;
      case 'Inactive':
        filtered = filtered.where((payment) => !payment.isActive).toList();
        break;
      // 'All' shows everything
    }

    // Apply sorting
    switch (_paymentSort) {
      case 'Name':
        filtered.sort((a, b) => a.paymentModeName.compareTo(b.paymentModeName));
        break;
      case 'Type':
        filtered.sort((a, b) => a.type.compareTo(b.type));
        break;
      case 'Date':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    setState(() {
      _filteredPaymentModes = filtered;
    });
  }

  // ══════════════════════════════════════════════════════════════
  // Payments Management Methods
  // ══════════════════════════════════════════════════════════════

  /// Apply comprehensive filtering and sorting to payments
  ///
  /// This method implements advanced filtering logic that supports:
  /// - Multi-field text search (event name, person name, reference)
  /// - Date range filtering (from/to dates)
  /// - Payment mode filtering (Cash, UPI, etc.)
  /// - Payment status filtering (Pending, Partial, Full)
  /// - Multiple sorting options (Date, Amount, Status, Payment Mode)
  void _applyPaymentsFiltersAndSort() {
    List<Payment> filtered = _payments;

    // Apply search filter
    if (_paymentsSearchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        final searchLower = _paymentsSearchQuery.toLowerCase();
        return payment.paymentId.toLowerCase().contains(searchLower) ||
            payment.customerEventNo.toLowerCase().contains(searchLower) ||
            payment.payingPersonName.toLowerCase().contains(searchLower) ||
            payment.reference?.toLowerCase().contains(searchLower) == true;
      }).toList();
    }

    // Apply status filter
    if (_paymentsFilter != 'All') {
      filtered = filtered.where((payment) {
        switch (_paymentsFilter) {
          case 'Pending':
            return payment.status == 'pending';
          case 'Partial':
            return payment.status == 'partial';
          case 'Full':
            return payment.status == 'full';
          default:
            return true;
        }
      }).toList();
    }

    // Apply payment mode filter
    if (_paymentsPaymentModeFilter != 'All') {
      filtered = filtered.where((payment) {
        // Compare using display names for consistency
        return Payment.getPaymentTypeDisplayName(payment.paymentType) ==
            _paymentsPaymentModeFilter;
      }).toList();
    }

    // Apply date range filter
    if (_paymentsFromDate != null) {
      filtered = filtered.where((payment) {
        return payment.paymentDate.isAfter(_paymentsFromDate!) ||
            payment.paymentDate.isAtSameMomentAs(_paymentsFromDate!);
      }).toList();
    }
    if (_paymentsToDate != null) {
      filtered = filtered.where((payment) {
        return payment.paymentDate.isBefore(
              _paymentsToDate!.add(const Duration(days: 1)),
            ) ||
            payment.paymentDate.isAtSameMomentAs(_paymentsToDate!);
      }).toList();
    }

    // Apply sort
    switch (_paymentsSort) {
      case 'Amount':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Status':
        filtered.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'PaymentMode':
        filtered.sort((a, b) => a.paymentType.compareTo(b.paymentType));
        break;
      case 'Date':
      default:
        filtered.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        break;
    }

    setState(() {
      _filteredPayments = filtered;
    });

    // Load payment summaries for grouped view
    _loadPaymentSummaries();
  }

  Future<void> _loadPaymentSummaries() async {
    try {
      final paymentSummaryService = PaymentSummaryService();
      final summaries = await paymentSummaryService.getPaymentSummaries();
      setState(() {
        _paymentSummaries = summaries;
      });
    } catch (e) {
      print('Error loading payment summaries: $e');
    }
  }

  void _onPaymentsSearchChanged(String query) {
    setState(() {
      _paymentsSearchQuery = query;
    });
    _applyPaymentsFiltersAndSort();
  }

  // Dialog Methods
  Future<void> _showAddExpenseTypeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ExpenseTypeDialog(),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _showEditExpenseTypeDialog(ExpenseType expenseType) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ExpenseTypeDialog(expenseType: expenseType),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _showAddPaymentDialog() async {
    showAddPaymentDialog(context);
    // Reload data after dialog closes
    await Future.delayed(const Duration(milliseconds: 500));
    _loadData();
  }

  Future<void> _showEditPaymentDialog(Payment payment) async {
    showAddPaymentDialog(context, payment: payment);
    // Reload data after dialog closes
    await Future.delayed(const Duration(milliseconds: 500));
    _loadData();
  }

  Future<void> _deletePayment(String paymentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text(
          'Are you sure you want to delete this payment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final paymentService = PaymentService();
        final success = await paymentService.deletePayment(paymentId);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete payment'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting payment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showPaymentDetailsDialog(PaymentSummary summary) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details - ${summary.customerEventNo}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary.eventName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Customer:'),
                  Text(
                    summary.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Agreed Amount:'),
                  Text(
                    '₹${summary.agreedAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Paid:'),
                  Text(
                    '₹${summary.totalPaid.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: summary.isOverpaid ? Colors.orange : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(summary.isOverpaid ? 'Overpaid by:' : 'Remaining:'),
                  Text(
                    '₹${summary.remainingAmount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: summary.isOverpaid ? Colors.orange : Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Individual Payments:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...summary.payments.map(
                (payment) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    title: Text('₹${payment.amount.toStringAsFixed(2)}'),
                    subtitle: Text(
                      '${payment.payingPersonName} - ${_formatDate(payment.paymentDate)}',
                    ),
                    trailing: Text(payment.statusDisplayName),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Delete Methods
  Future<void> _deleteExpenseType(ExpenseType expenseType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense Type'),
        content: Text(
          'Are you sure you want to delete "${expenseType.expenseTypeName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _expenseTypeService.deleteExpenseType(expenseType.expenseTypeId);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense type deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting expense type: $e')),
          );
        }
      }
    }
  }

  // Toggle Status Methods
  Future<void> _toggleExpenseTypeStatus(ExpenseType expenseType) async {
    try {
      await _expenseTypeService.toggleExpenseTypeStatus(
        expenseType.expenseTypeId,
      );
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Expense type ${expenseType.isActive ? 'deactivated' : 'activated'} successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating expense type: $e')),
        );
      }
    }
  }

  // Export Methods
  Future<void> _exportExpenseTypesToCSV() async {
    try {
      final filePath = await CsvExportService.exportExpenseTypesToCSV(
        _filteredExpenseTypes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense types exported to: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting expense types: $e')),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Widget Build Method & UI Components
  // ══════════════════════════════════════════════════════════════

  /// Main widget build method
  /// Creates tabbed interface for expense types and payments management
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 8),
                      const Text('Expense Types'),
                      if (_expenseTypes.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_expenseTypes.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long),
                      const SizedBox(width: 8),
                      const Text('Payments'),
                      if (_payments.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_payments.length}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildExpenseTypesTab(), _buildPaymentsTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTypesTab() {
    return Column(
      children: [
        // Standardized Header for Expense Types
        StandardizedPageHeader(
          showViewToggle: false,
          onAdd: _showAddExpenseTypeDialog,
          addButtonLabel: 'Add Expense Type',
          addButtonIcon: Icons.add,
          showExportButton: true,
          onExport: _exportExpenseTypesToCSV,
          exportButtonLabel: 'Export CSV',
          exportButtonColor: Colors.green,
        ),

        // Standardized Search and Filter for Expense Types
        StandardizedSearchFilter(
          searchController: _expenseSearchController,
          onSearchChanged: _onExpenseSearchChanged,
          searchHint: 'Search expense types...',
          filterOptions: const [
            FilterOption(label: 'All', value: 'All'),
            FilterOption(label: 'Active', value: 'Active'),
            FilterOption(label: 'Inactive', value: 'Inactive'),
          ],
          selectedFilter: _expenseFilter,
          onFilterChanged: (filter) {
            setState(() => _expenseFilter = filter);
            _applyExpenseFiltersAndSort();
          },
          sortOptions: const [
            SortOption(label: 'Name', value: 'Name'),
            SortOption(label: 'Category', value: 'Category'),
            SortOption(label: 'Date', value: 'Date'),
          ],
          selectedSort: _expenseSort,
          sortAscending: true,
          onSortChanged: (sort) {
            setState(() => _expenseSort = sort);
            _applyExpenseFiltersAndSort();
          },
        ),

        // Results Counter
        StandardizedResultsCounter(
          count: _filteredExpenseTypes.length,
          singularLabel: 'expense type',
          pluralLabel: 'expense types',
          icon: Icons.category,
        ),

        // Expense Types List
        Expanded(
          child: _filteredExpenseTypes.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expense types found.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add your first expense type!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredExpenseTypes.length,
                    itemBuilder: (context, index) {
                      final expenseType = _filteredExpenseTypes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: expenseType.isActive
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.errorContainer,
                            child: Icon(
                              Icons.category,
                              color: expenseType.isActive
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                            ),
                          ),
                          title: Text(
                            expenseType.expenseTypeName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: expenseType.isActive
                                  ? null
                                  : Theme.of(context).disabledColor,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${expenseType.expenseTypeId}'),
                              Text('Category: ${expenseType.category}'),
                              if (expenseType.description != null &&
                                  expenseType.description!.isNotEmpty)
                                Text('Description: ${expenseType.description}'),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: expenseType.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      expenseType.isActive
                                          ? 'Active'
                                          : 'Inactive',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showEditExpenseTypeDialog(expenseType);
                                  break;
                                case 'toggle':
                                  _toggleExpenseTypeStatus(expenseType);
                                  break;
                                case 'delete':
                                  _deleteExpenseType(expenseType);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit'),
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: ListTile(
                                  leading: Icon(
                                    expenseType.isActive
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  title: Text(
                                    expenseType.isActive
                                        ? 'Deactivate'
                                        : 'Activate',
                                  ),
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    Widget content = Column(
      children: [
        // Header with Add Button and Export Button
        Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _showAddPaymentDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Data refreshed successfully',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.inverseSurface,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showGroupedView = !_showGroupedView;
                  });
                },
                icon: Icon(
                  _showGroupedView ? Icons.view_list : Icons.view_module,
                  size: 18,
                ),
                label: Text(
                  _showGroupedView ? 'Individual View' : 'Grouped View',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                ),
              ),
              // Only show Table View button in individual view
              if (!_showGroupedView)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTableView = !_showTableView;
                    });
                  },
                  icon: Icon(
                    _showTableView ? Icons.view_list : Icons.table_chart,
                    size: 18,
                  ),
                  label: Text(_showTableView ? 'Card View' : 'Table View'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
              ElevatedButton.icon(
                onPressed: () {
                  _exportPaymentsToCSV();
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // Search and Filters
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search Bar (always visible)
              TextField(
                controller: _paymentsSearchController,
                onChanged: _onPaymentsSearchChanged,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: _showGroupedView
                      ? 'Search by event name or reference...'
                      : 'Search by event name, person name, or reference...',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _paymentsSearchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _paymentsSearchController.clear();
                            _onPaymentsSearchChanged('');
                          },
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Filters Toggle Button
              InkWell(
                onTap: () {
                  setState(() {
                    _isFiltersExpanded = !_isFiltersExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Advanced Filters & Sort',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      AnimatedRotation(
                        turns: _isFiltersExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expandable Filter Section
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isFiltersExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Date Range Filter
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From Date:',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _paymentsFromDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _paymentsFromDate = date;
                                      });
                                      _applyPaymentsFiltersAndSort();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _paymentsFromDate != null
                                              ? '${_paymentsFromDate!.day}/${_paymentsFromDate!.month}/${_paymentsFromDate!.year}'
                                              : 'Select date',
                                          style: TextStyle(
                                            color: _paymentsFromDate != null
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To Date:',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _paymentsToDate ?? DateTime.now(),
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 365),
                                      ),
                                    );
                                    if (date != null) {
                                      setState(() {
                                        _paymentsToDate = date;
                                      });
                                      _applyPaymentsFiltersAndSort();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _paymentsToDate != null
                                              ? '${_paymentsToDate!.day}/${_paymentsToDate!.month}/${_paymentsToDate!.year}'
                                              : 'Select date',
                                          style: TextStyle(
                                            color: _paymentsToDate != null
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_paymentsFromDate != null ||
                              _paymentsToDate != null)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _paymentsFromDate = null;
                                  _paymentsToDate = null;
                                });
                                _applyPaymentsFiltersAndSort();
                              },
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter by Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by Status:',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children: ['All', 'Pending', 'Partial', 'Full'].map(
                              (filter) {
                                return FilterChip(
                                  label: Text(
                                    filter,
                                    style: TextStyle(
                                      color: _paymentsFilter == filter
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                  ),
                                  selected: _paymentsFilter == filter,
                                  selectedColor: Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  onSelected: (selected) {
                                    setState(() {
                                      _paymentsFilter = filter;
                                    });
                                    _applyPaymentsFiltersAndSort();
                                  },
                                );
                              },
                            ).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter by Payment Mode
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by Payment Mode:',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children:
                                [
                                  'All',
                                  ...Payment.paymentTypes.map(
                                    (type) =>
                                        Payment.getPaymentTypeDisplayName(type),
                                  ),
                                ].map((filter) {
                                  return FilterChip(
                                    label: Text(
                                      filter,
                                      style: TextStyle(
                                        color:
                                            _paymentsPaymentModeFilter == filter
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSecondaryContainer
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    selected:
                                        _paymentsPaymentModeFilter == filter,
                                    selectedColor: Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    onSelected: (selected) {
                                      setState(() {
                                        _paymentsPaymentModeFilter = filter;
                                      });
                                      _applyPaymentsFiltersAndSort();
                                    },
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sort Options
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sort by:',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            children:
                                [
                                  'Date',
                                  'Amount',
                                  'Status',
                                  'PaymentMode',
                                ].map((sort) {
                                  String displayName = sort;
                                  if (sort == 'PaymentMode')
                                    displayName = 'Payment Mode';

                                  return ActionChip(
                                    label: Text(
                                      displayName,
                                      style: TextStyle(
                                        color: _paymentsSort == sort
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                    ),
                                    backgroundColor: _paymentsSort == sort
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(context).colorScheme.surface,
                                    onPressed: () {
                                      setState(() {
                                        _paymentsSort = sort;
                                      });
                                      _applyPaymentsFiltersAndSort();
                                    },
                                  );
                                }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _showGroupedView
                  ? '${_paymentSummaries.length} customer events with payments'
                  : '${_filteredPayments.length} payment records found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),

        // Payment Records List
        Expanded(
          child: _showGroupedView
              ? _buildGroupedPaymentView()
              : _buildIndividualPaymentView(),
        ),
      ],
    );

    // Return content with horizontal scrollbar at the bottom when in table view
    return (!_showGroupedView && _showTableView)
        ? Scrollbar(
            controller: _tableHorizontalController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _tableHorizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(
                  context,
                ).size.width.clamp(1200.0, double.infinity),
                child: content,
              ),
            ),
          )
        : content;
  }

  Widget _buildGroupedPaymentView() {
    if (_paymentSummaries.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group_work,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No payment summaries found.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record payments to see grouped summaries!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _paymentSummaries.length,
      itemBuilder: (context, index) {
        final summary = _paymentSummaries[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with event details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event: ${summary.customerEventNo}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.eventName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: summary.statusColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        summary.status,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Progress',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        Text(
                          '${(summary.paymentProgress * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: summary.paymentProgress.clamp(0.0, 1.0),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          summary.isOverpaid
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Payment details
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPaymentDetailRow(
                            'Agreed Amount:',
                            '₹${summary.agreedAmount.toStringAsFixed(2)}',
                            Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(height: 4),
                          _buildPaymentDetailRow(
                            'Total Paid:',
                            '₹${summary.totalPaid.toStringAsFixed(2)}',
                            summary.isOverpaid
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 4),
                          _buildPaymentDetailRow(
                            summary.isOverpaid ? 'Overpaid by:' : 'Remaining:',
                            '₹${summary.remainingAmount.abs().toStringAsFixed(2)}',
                            summary.isOverpaid
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${summary.payments.length}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          'Payments',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _showAddPaymentDialog();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        _showPaymentDetailsDialog(summary);
                      },
                      icon: Icon(
                        Icons.visibility,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'View Details',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualPaymentView() {
    if (_filteredPayments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No payment records found.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Record your first payment!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _showTableView ? _buildPaymentTable() : _buildPaymentCards();
  }

  Widget _buildPaymentTable() {
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            controller: _tableVerticalController,
            child: SingleChildScrollView(
              controller: _tableVerticalController,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 16,
                  columns: const [
                    DataColumn(label: Text('Payment ID')),
                    DataColumn(label: Text('Event')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Paying Person')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Agreed Amount')),
                    DataColumn(label: Text('Remaining')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Reference')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: _filteredPayments.map((payment) {
                    return DataRow(
                      cells: [
                        DataCell(Text(payment.paymentId)),
                        DataCell(Text(payment.customerEventNo)),
                        DataCell(
                          FutureBuilder<String>(
                            future: _getCustomerName(payment.customerEventNo),
                            builder: (context, snapshot) {
                              return Text(snapshot.data ?? 'Loading...');
                            },
                          ),
                        ),
                        DataCell(Text(payment.payingPersonName)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getPaymentIcon(payment.paymentType),
                                size: 16,
                                color: _getPaymentTypeColor(
                                  payment.paymentType,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(payment.paymentTypeDisplayName),
                            ],
                          ),
                        ),
                        DataCell(Text('₹${payment.amount.toStringAsFixed(2)}')),
                        DataCell(
                          FutureBuilder<double>(
                            future: _getAgreedAmount(payment.customerEventNo),
                            builder: (context, snapshot) {
                              return Text(
                                '₹${(snapshot.data ?? 0.0).toStringAsFixed(2)}',
                              );
                            },
                          ),
                        ),
                        DataCell(
                          FutureBuilder<double>(
                            future: _getRemainingAmount(
                              payment.customerEventNo,
                            ),
                            builder: (context, snapshot) {
                              final remaining = snapshot.data ?? 0.0;
                              return Text(
                                '₹${remaining.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: remaining < 0
                                      ? Colors.orange
                                      : remaining > 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPaymentStatusColor(payment.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payment.statusDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(_formatDate(payment.paymentDate))),
                        DataCell(Text(payment.reference ?? '-')),
                        DataCell(
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showEditPaymentDialog(payment);
                                  break;
                                case 'delete':
                                  _deletePayment(payment.paymentId);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit),
                                  title: Text('Edit'),
                                  dense: true,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ), // closes DataTable
              ), // closes ConstrainedBox
            ), // closes vertical SingleChildScrollView
          ), // closes vertical Scrollbar
        ), // closes Expanded
      ], // closes Column children
    ); // closes Column
  }

  Widget _buildPaymentCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = _filteredPayments[index];
        return Card(
          color: Theme.of(context).colorScheme.surface,
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPaymentStatusColor(payment.status),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Icon(_getPaymentStatusIcon(payment.status)),
            ),
            title: Text(
              'Payment: ${payment.paymentId}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Event: ${payment.customerEventNo}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Paid by: ${payment.payingPersonName}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Type: ${payment.paymentTypeDisplayName}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Amount: ₹${payment.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Date: ${_formatDate(payment.paymentDate)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (payment.reference != null)
                  Text(
                    'Ref: ${payment.reference}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(payment.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    payment.statusDisplayName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  color: Theme.of(context).colorScheme.surface,
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditPaymentDialog(payment);
                        break;
                      case 'delete':
                        _deletePayment(payment.paymentId);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          'Edit',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        dense: true,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              // TODO: Show payment details dialog
            },
          ),
        );
      },
    );
  }

  Future<String> _getCustomerName(String customerEventNo) async {
    try {
      final customerEvents = await CustomerEventService()
          .getAllCustomerEvents();
      final event = customerEvents.firstWhere(
        (e) => e.eventNo == customerEventNo,
        orElse: () => throw Exception('Event not found'),
      );
      return event.customerName;
    } catch (e) {
      return 'Unknown';
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Utility Methods & Calculations
  // ══════════════════════════════════════════════════════════════

  /// Get the agreed amount for a specific customer event
  /// Used for calculating remaining amounts in payments table
  Future<double> _getAgreedAmount(String customerEventNo) async {
    try {
      final customerEvents = await CustomerEventService()
          .getAllCustomerEvents();
      final event = customerEvents.firstWhere(
        (e) => e.eventNo == customerEventNo,
        orElse: () => throw Exception('Event not found'),
      );
      return event.agreedAmount;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate remaining amount (agreed amount - total payments) for a customer event
  /// Used to display outstanding balance in payments table
  Future<double> _getRemainingAmount(String customerEventNo) async {
    try {
      final customerEvents = await CustomerEventService()
          .getAllCustomerEvents();
      final event = customerEvents.firstWhere(
        (e) => e.eventNo == customerEventNo,
        orElse: () => throw Exception('Event not found'),
      );

      // Calculate total paid for this event
      final eventPayments = _payments
          .where((p) => p.customerEventNo == customerEventNo)
          .toList();
      final totalPaid = eventPayments.fold(
        0.0,
        (sum, payment) => sum + payment.amount,
      );

      return event.agreedAmount - totalPaid;
    } catch (e) {
      return 0.0;
    }
  }

  Color _getPaymentTypeColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'cheque':
        return Colors.brown;
      case 'bank_transfer':
        return Colors.blue;
      case 'upi':
        return Colors.purple;
      case 'card':
        return Colors.orange;
      case 'netbanking':
        return Colors.teal;
      case 'other':
        return Colors.grey;
      case 'adjustment':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportPaymentsToCSV() async {
    try {
      final filePath = await CsvExportService.exportPaymentsToCSV(
        _filteredPayments,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payments exported to: $filePath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting payments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      case 'full':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'partial':
        return Icons.hourglass_bottom;
      case 'full':
        return Icons.check_circle;
      default:
        return Icons.payment;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getPaymentIcon(String type) {
    switch (type) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'upi':
        return Icons.phone_android;
      case 'cheque':
        return Icons.receipt_long;
      case 'netbanking':
        return Icons.laptop;
      case 'other':
        return Icons.payment;
      case 'adjustment':
        return Icons.tune;
      default:
        return Icons.payment;
    }
  }
}
