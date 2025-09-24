import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/customer_event.dart';
import '../models/expense_type.dart';
import '../services/event_service.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/customer_event_service.dart';
import '../services/expense_type_service.dart';

class EventDialog {
  static void showAddEventDialog(BuildContext context) async {
    final EventService eventService = EventService();
    final CustomerService customerService = CustomerService();
    final ProductService productService = ProductService();
    final CustomerEventService customerEventService = CustomerEventService();
    final ExpenseTypeService expenseTypeService = ExpenseTypeService();

    // Generate the event number automatically
    final generatedEventNo = await eventService.generateEventNo();

    // Load customers, products, customer events, and expense types for dropdowns
    final customers = await customerService.getAllCustomers();
    final products = await productService.getAllProducts();
    final customerEvents = await customerEventService.getAllCustomerEvents();
    final expenseTypes = await expenseTypeService.getAllExpenseTypes();

    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add customers first before creating events'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add products first before creating events'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final eventNameController = TextEditingController();
    final expenseTypeController = TextEditingController();
    final expenseNameController = TextEditingController();
    final amountController = TextEditingController(text: '0.0');

    Customer? selectedCustomer;
    Product? selectedProduct;
    CustomerEvent? selectedCustomerEvent;
    ExpenseType? selectedExpenseType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Daily Activity'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show generated event number
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event No. (Auto-generated)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          generatedEventNo,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: eventNameController,
                    decoration: const InputDecoration(
                      labelText: 'Event Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.event),
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  // Customer Dropdown
                  DropdownButtonFormField<Customer>(
                    value: selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'Customer *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: customers.map((customer) {
                      return DropdownMenuItem<Customer>(
                        value: customer,
                        child: Text(
                          '${customer.custId} - ${customer.customerName}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Customer? customer) {
                      setState(() {
                        selectedCustomer = customer;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Product Dropdown
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Product *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                    items: products.map((product) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Text(
                          '${product.productId} - ${product.productName}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Product? product) {
                      setState(() {
                        selectedProduct = product;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Customer Event Dropdown (Optional)
                  DropdownButtonFormField<CustomerEvent>(
                    value: selectedCustomerEvent,
                    decoration: const InputDecoration(
                      labelText: 'Link to Customer Event (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                      helperText:
                          'Select to link this daily event to a customer event',
                    ),
                    items: [
                      const DropdownMenuItem<CustomerEvent>(
                        value: null,
                        child: Text('No Customer Event'),
                      ),
                      ...customerEvents.map((customerEvent) {
                        return DropdownMenuItem<CustomerEvent>(
                          value: customerEvent,
                          child: Text(
                            '${customerEvent.eventNo} - ${customerEvent.eventName}',
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (CustomerEvent? customerEvent) {
                      setState(() {
                        selectedCustomerEvent = customerEvent;
                        // Auto-fill customer and product from selected customer event
                        if (customerEvent != null) {
                          selectedCustomer = customers.firstWhere(
                            (c) => c.custId == customerEvent.custId,
                            orElse: () => selectedCustomer!,
                          );
                          selectedProduct = products.firstWhere(
                            (p) => p.productId == customerEvent.productId,
                            orElse: () => selectedProduct!,
                          );
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ExpenseType>(
                    value: selectedExpenseType,
                    decoration: const InputDecoration(
                      labelText: 'Expense Type *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      helperText: 'Select an expense type from the dropdown',
                    ),
                    hint: const Text('Select Expense Type'),
                    isExpanded: true,
                    items: expenseTypes
                        .where((expenseType) => expenseType.isActive)
                        .map(
                          (expenseType) => DropdownMenuItem<ExpenseType>(
                            value: expenseType,
                            child: Text(
                              '${expenseType.expenseTypeName} (${expenseType.category})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (ExpenseType? value) {
                      setState(() {
                        selectedExpenseType = value;
                        expenseTypeController.text =
                            value?.expenseTypeName ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an expense type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: expenseNameController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      helperText: 'Detailed description of the expense',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_rupee),
                      helperText: 'Enter amount in rupees',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final eventName = eventNameController.text.trim();
                final expenseName = expenseNameController.text.trim();
                final amountText = amountController.text.trim();

                // Validation
                if (eventName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event name is required')),
                  );
                  return;
                }

                if (selectedCustomer == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a customer')),
                  );
                  return;
                }

                if (selectedProduct == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a product')),
                  );
                  return;
                }

                if (selectedExpenseType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select an expense type'),
                    ),
                  );
                  return;
                }

                if (expenseName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense name is required')),
                  );
                  return;
                }

                final amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid amount greater than 0',
                      ),
                    ),
                  );
                  return;
                }

                final newEvent = Event(
                  eventNo: generatedEventNo,
                  eventName: eventName,
                  custId: selectedCustomer!.custId,
                  productId: selectedProduct!.productId,
                  customerName: selectedCustomer!.customerName,
                  expenseType: selectedExpenseType!.expenseTypeName,
                  expenseName: expenseName,
                  amount: amount,
                  eventDate: DateTime.now(),
                  customerEventNo: selectedCustomerEvent?.eventNo,
                );

                try {
                  final success = await eventService.createEvent(newEvent);

                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Activity "$eventName" created successfully!',
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to create activity. Please try again.',
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating event: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Create Activity'),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditEventDialog(BuildContext context, Event event) async {
    final EventService eventService = EventService();
    final CustomerService customerService = CustomerService();
    final ProductService productService = ProductService();
    final CustomerEventService customerEventService = CustomerEventService();
    final ExpenseTypeService expenseTypeService = ExpenseTypeService();

    // Load customers, products, customer events, and expense types for dropdowns
    final customers = await customerService.getAllCustomers();
    final products = await productService.getAllProducts();
    final customerEvents = await customerEventService.getAllCustomerEvents();
    final expenseTypes = await expenseTypeService.getAllExpenseTypes();

    // Pre-fill controllers with existing event data
    final eventNameController = TextEditingController(text: event.eventName);
    final expenseTypeController = TextEditingController(
      text: event.expenseType,
    );
    final expenseNameController = TextEditingController(
      text: event.expenseName,
    );
    final amountController = TextEditingController(
      text: event.amount.toString(),
    );

    // Pre-select the existing values
    Customer? selectedCustomer;
    try {
      selectedCustomer = customers.firstWhere((c) => c.custId == event.custId);
    } catch (e) {
      selectedCustomer = customers.isNotEmpty ? customers.first : null;
    }

    Product? selectedProduct;
    try {
      selectedProduct = products.firstWhere(
        (p) => p.productId == event.productId,
      );
    } catch (e) {
      selectedProduct = products.isNotEmpty ? products.first : null;
    }

    CustomerEvent? selectedCustomerEvent;
    if (event.customerEventNo != null) {
      try {
        selectedCustomerEvent = customerEvents.firstWhere(
          (ce) => ce.eventNo == event.customerEventNo,
        );
      } catch (e) {
        selectedCustomerEvent = null;
      }
    }

    ExpenseType? selectedExpenseType;
    try {
      selectedExpenseType = expenseTypes.firstWhere(
        (et) => et.expenseTypeName == event.expenseType,
      );
    } catch (e) {
      selectedExpenseType = null;
    }

    DateTime selectedDate = event.eventDate ?? DateTime.now();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Edit Activity - ${event.eventNo}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Event Name
                    TextField(
                      controller: eventNameController,
                      decoration: const InputDecoration(
                        labelText: 'Event Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Customer Dropdown
                    DropdownButtonFormField<Customer>(
                      value: selectedCustomer,
                      decoration: const InputDecoration(
                        labelText: 'Customer *',
                        border: OutlineInputBorder(),
                      ),
                      items: customers.map((customer) {
                        return DropdownMenuItem<Customer>(
                          value: customer,
                          child: Text(
                            '${customer.customerName} (${customer.custId})',
                          ),
                        );
                      }).toList(),
                      onChanged: (Customer? newValue) {
                        setState(() {
                          selectedCustomer = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Product Dropdown
                    DropdownButtonFormField<Product>(
                      value: selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Product *',
                        border: OutlineInputBorder(),
                      ),
                      items: products.map((product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: Text(
                            '${product.productName} (${product.productId})',
                          ),
                        );
                      }).toList(),
                      onChanged: (Product? newValue) {
                        setState(() {
                          selectedProduct = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Customer Event Dropdown (Optional)
                    DropdownButtonFormField<CustomerEvent>(
                      value: selectedCustomerEvent,
                      decoration: const InputDecoration(
                        labelText: 'Customer Event (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<CustomerEvent>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...customerEvents.map((customerEvent) {
                          return DropdownMenuItem<CustomerEvent>(
                            value: customerEvent,
                            child: Text(
                              '${customerEvent.eventName} (${customerEvent.eventNo})',
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (CustomerEvent? newValue) {
                        setState(() {
                          selectedCustomerEvent = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expense Type
                    DropdownButtonFormField<ExpenseType>(
                      value: selectedExpenseType,
                      decoration: const InputDecoration(
                        labelText: 'Expense Type *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                        helperText: 'Select an expense type from the dropdown',
                      ),
                      hint: const Text('Select Expense Type'),
                      isExpanded: true,
                      items: expenseTypes
                          .where((expenseType) => expenseType.isActive)
                          .map(
                            (expenseType) => DropdownMenuItem<ExpenseType>(
                              value: expenseType,
                              child: Text(
                                '${expenseType.expenseTypeName} (${expenseType.category})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (ExpenseType? value) {
                        setState(() {
                          selectedExpenseType = value;
                          expenseTypeController.text =
                              value?.expenseTypeName ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select an expense type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Expense Name
                    TextField(
                      controller: expenseNameController,
                      decoration: const InputDecoration(
                        labelText: 'Expense Name *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount *',
                        border: OutlineInputBorder(),
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate required fields
                    if (eventNameController.text.isEmpty ||
                        selectedCustomer == null ||
                        selectedProduct == null ||
                        selectedExpenseType == null ||
                        expenseNameController.text.isEmpty ||
                        amountController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Validate amount
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid amount'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final updatedEvent = Event(
                      eventNo: event.eventNo, // Keep the same event number
                      eventName: eventNameController.text.trim(),
                      custId: selectedCustomer!.custId,
                      productId: selectedProduct!.productId,
                      customerName: selectedCustomer!.customerName,
                      expenseType: selectedExpenseType!.expenseTypeName,
                      expenseName: expenseNameController.text.trim(),
                      amount: amount,
                      eventDate: selectedDate,
                      customerEventNo: selectedCustomerEvent?.eventNo,
                    );

                    final success = await eventService.updateEvent(
                      updatedEvent,
                    );

                    if (success) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Activity updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to update event'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Update Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
