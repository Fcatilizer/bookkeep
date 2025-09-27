import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../models/customer_event.dart';
import '../models/expense_type.dart';
import '../services/event_service.dart';
import '../services/customer_event_service.dart';
import '../services/expense_type_service.dart';

class DailyExpenseDialog {
  static Future<void> showAddExpenseDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _DailyExpenseDialogWidget();
      },
    );
  }

  static Future<void> showEditExpenseDialog(
    BuildContext context,
    Event expense,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _DailyExpenseDialogWidget(expense: expense);
      },
    );
  }
}

class _DailyExpenseDialogWidget extends StatefulWidget {
  final Event? expense;

  const _DailyExpenseDialogWidget({this.expense});

  @override
  State<_DailyExpenseDialogWidget> createState() =>
      _DailyExpenseDialogWidgetState();
}

class _DailyExpenseDialogWidgetState extends State<_DailyExpenseDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final CustomerEventService _customerEventService = CustomerEventService();
  final ExpenseTypeService _expenseTypeService = ExpenseTypeService();

  // Form controllers
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Form state
  CustomerEvent? _selectedCustomerEvent;
  ExpenseType? _selectedExpenseType;
  bool _isLoading = false;

  // Data lists
  List<CustomerEvent> _customerEvents = [];
  List<ExpenseType> _expenseTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.expense != null) {
      final expense = widget.expense!;
      _remarksController.text = expense.expenseName;
      _amountController.text = expense.amount.toString();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load customer events and expense types
      final customerEvents = await _customerEventService.getAllCustomerEvents();
      final expenseTypes = await _expenseTypeService.getAllExpenseTypes();

      setState(() {
        _customerEvents = customerEvents
            .where((event) => event.status == 'active')
            .toList();
        _expenseTypes = expenseTypes.where((type) => type.isActive).toList();

        // If editing, find and set the selected customer event and expense type
        if (widget.expense != null) {
          final expense = widget.expense!;

          // Find matching customer event by event number if available
          if (expense.customerEventNo != null) {
            _selectedCustomerEvent = _customerEvents
                .where((ce) => ce.eventNo == expense.customerEventNo)
                .firstOrNull;
          }

          // Find matching expense type
          _selectedExpenseType = _expenseTypes
              .where((et) => et.expenseTypeName == expense.expenseType)
              .firstOrNull;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomerEvent == null || _selectedExpenseType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Customer Event and Expense Type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      final remarks = _remarksController.text.trim().isEmpty
          ? _selectedExpenseType!.expenseTypeName
          : _remarksController.text.trim();

      if (widget.expense != null) {
        // Update existing expense
        final updatedExpense = Event(
          eventNo: widget.expense!.eventNo,
          eventName: remarks,
          custId: _selectedCustomerEvent!.custId,
          productId: (_selectedCustomerEvent!.productId.isEmpty)
              ? ''
              : _selectedCustomerEvent!.productId,
          customerName: _selectedCustomerEvent!.customerName,
          expenseType: _selectedExpenseType!.expenseTypeName,
          expenseName: remarks,
          amount: amount,
          eventDate: DateTime.now(),
          customerEventNo: _selectedCustomerEvent!.eventNo,
        );

        final success = await _eventService.updateEvent(updatedExpense);

        if (success) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Daily expense updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to update expense');
        }
      } else {
        // Create new expense
        final eventNo = await _eventService.generateEventNo();

        final newExpense = Event(
          eventNo: eventNo,
          eventName: remarks,
          custId: _selectedCustomerEvent!.custId,
          productId: (_selectedCustomerEvent!.productId.isEmpty)
              ? ''
              : _selectedCustomerEvent!.productId,
          customerName: _selectedCustomerEvent!.customerName,
          expenseType: _selectedExpenseType!.expenseTypeName,
          expenseName: remarks,
          amount: amount,
          eventDate: DateTime.now(),
          customerEventNo: _selectedCustomerEvent!.eventNo,
        );

        final success = await _eventService.createEvent(newExpense);

        if (success) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Daily expense added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to add expense');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.expense != null ? 'Edit Daily Expense' : 'Add Daily Expense',
      ),
      content: _isLoading
          ? const SizedBox(
              width: 400,
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 500,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Event Selection
                      Text(
                        'Select Customer Event *',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<CustomerEvent>(
                        value: _selectedCustomerEvent,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose a customer event',
                          prefixIcon: Icon(Icons.event),
                        ),
                        items: _customerEvents.map((customerEvent) {
                          return DropdownMenuItem(
                            value: customerEvent,
                            child: Tooltip(
                              message: 'Event No: ${customerEvent.eventNo}',
                              child: Text(
                                customerEvent.eventName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (CustomerEvent? value) {
                          setState(() {
                            _selectedCustomerEvent = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a customer event';
                          }
                          return null;
                        },
                        isExpanded: true,
                      ),

                      const SizedBox(height: 16),

                      // Customer Name (Auto-filled, read-only)
                      Text(
                        'Customer Name',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue:
                            _selectedCustomerEvent?.customerName ?? '',
                        key: ValueKey(
                          'customer_name_${_selectedCustomerEvent?.customerName}',
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        readOnly: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Product (Auto-filled if available, read-only)
                      Text(
                        'Product',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue:
                            (_selectedCustomerEvent == null ||
                                _selectedCustomerEvent!.productId.isEmpty)
                            ? 'No product assigned'
                            : _selectedCustomerEvent!.productId,
                        key: ValueKey(
                          'product_${_selectedCustomerEvent?.productId}',
                        ),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        readOnly: true,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle:
                              (_selectedCustomerEvent == null ||
                                  _selectedCustomerEvent!.productId.isEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Expense Type Selection
                      Text(
                        'Select Expense Type *',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ExpenseType>(
                        value: _selectedExpenseType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Choose an expense type',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _expenseTypes.map((expenseType) {
                          return DropdownMenuItem(
                            value: expenseType,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expenseType.expenseTypeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (expenseType.category.isNotEmpty)
                                  Text(
                                    'Category: ${expenseType.category}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (ExpenseType? value) {
                          setState(() {
                            _selectedExpenseType = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an expense type';
                          }
                          return null;
                        },
                        isExpanded: true,
                      ),

                      const SizedBox(height: 16),

                      // Remarks (Optional)
                      Text(
                        'Remarks',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _remarksController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              'Enter expense remarks/description (optional)',
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          // Optional field - only validate if text is provided
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              value.trim().length < 3) {
                            return 'Remarks must be at least 3 characters if provided';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Amount
                      Text(
                        'Amount *',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter amount',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Please enter a valid amount';
                          }
                          if (amount <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6FAADB),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(widget.expense != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
