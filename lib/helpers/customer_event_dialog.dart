import 'package:flutter/material.dart';
import '../models/customer_event.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../services/customer_event_service.dart';
import '../services/customer_service.dart';
import '../services/product_service.dart';
import '../services/payment_service.dart';

class CustomerEventDialog {
  static void showAddCustomerEventDialog(BuildContext context) async {
    final CustomerEventService customerEventService = CustomerEventService();
    final CustomerService customerService = CustomerService();
    final ProductService productService = ProductService();

    // Generate the customer event ID automatically
    final generatedEventNo = await customerEventService
        .generateCustomerEventNo();

    // Load customers and products for dropdowns
    final customers = await customerService.getAllCustomers();
    final products = await productService.getAllProducts();

    if (customers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create at least one customer first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Note: Products are now optional for Customer Events

    final eventNameController = TextEditingController();
    final quantityController = TextEditingController(text: '1.0');
    final agreedAmountController = TextEditingController();

    Customer? selectedCustomer;
    Product? selectedProduct;
    String selectedStatus = 'active';
    DateTime selectedDate = DateTime.now();
    DateTime? selectedExpectedFinishingDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Customer Event'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show generated event number (read-only)
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
                          'Event Number (Auto-generated)',
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
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Event Name
                  TextField(
                    controller: eventNameController,
                    decoration: const InputDecoration(
                      labelText: 'Event Name *',
                      border: OutlineInputBorder(),
                      hintText: 'Enter event name',
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
                          '${customer.custId} - ${customer.customerName}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Customer? value) {
                      setState(() {
                        selectedCustomer = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Product Dropdown
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Product (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<Product>(
                        value: null,
                        child: Text('None (No Product)'),
                      ),
                      ...products.map((product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: Text(
                            '${product.productId} - ${product.productName}',
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (Product? value) {
                      setState(() {
                        selectedProduct = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Agreed Amount
                  TextField(
                    controller: agreedAmountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Agreed Amount *',
                      border: OutlineInputBorder(),
                      hintText: 'Enter agreed amount',
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        selectedStatus = value ?? 'active';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Event Date
                  InkWell(
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
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Event Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Expected Finishing Date
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                            selectedExpectedFinishingDate ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedExpectedFinishingDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Expected Finishing Date (Optional)',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedExpectedFinishingDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    selectedExpectedFinishingDate = null;
                                  });
                                },
                              ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                      child: Text(
                        selectedExpectedFinishingDate != null
                            ? '${selectedExpectedFinishingDate!.day}/${selectedExpectedFinishingDate!.month}/${selectedExpectedFinishingDate!.year}'
                            : 'Tap to select date',
                        style: TextStyle(
                          color: selectedExpectedFinishingDate != null
                              ? null
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    quantityController.text.isEmpty ||
                    agreedAmountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate amount
                final agreedAmount = double.tryParse(
                  agreedAmountController.text,
                );
                if (agreedAmount == null || agreedAmount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid agreed amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate quantity
                final quantity = double.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final newCustomerEvent = CustomerEvent(
                  eventNo: generatedEventNo,
                  eventName: eventNameController.text.trim(),
                  custId: selectedCustomer!.custId,
                  productId: selectedProduct?.productId ?? 'NONE',
                  customerName: selectedCustomer!.customerName,
                  quantity: quantity,
                  agreedAmount: agreedAmount,
                  eventDate: selectedDate,
                  expectedFinishingDate: selectedExpectedFinishingDate,
                  status: selectedStatus,
                );

                final success = await customerEventService.createCustomerEvent(
                  newCustomerEvent,
                );

                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Customer Event "${newCustomerEvent.eventName}" created successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to create customer event. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditCustomerEventDialog(
    BuildContext context,
    CustomerEvent customerEvent,
  ) async {
    final CustomerEventService customerEventService = CustomerEventService();
    final CustomerService customerService = CustomerService();
    final ProductService productService = ProductService();

    // Load customers and products for dropdowns
    final customers = await customerService.getAllCustomers();
    final products = await productService.getAllProducts();

    final eventNameController = TextEditingController(
      text: customerEvent.eventName,
    );
    final quantityController = TextEditingController(
      text: customerEvent.quantity.toString(),
    );
    final agreedAmountController = TextEditingController(
      text: customerEvent.agreedAmount.toString(),
    );

    Customer? selectedCustomer = customers.firstWhere(
      (c) => c.custId == customerEvent.custId,
      orElse: () => customers.first,
    );
    Product? selectedProduct = products.firstWhere(
      (p) => p.productId == customerEvent.productId,
      orElse: () => products.first,
    );
    String selectedStatus = customerEvent.status;
    DateTime selectedDate = customerEvent.eventDate ?? DateTime.now();
    DateTime? selectedExpectedFinishingDate =
        customerEvent.expectedFinishingDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Edit Customer Event: ${customerEvent.eventNo}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show event number (read-only)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Number',
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
                          customerEvent.eventNo,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

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
                          '${customer.custId} - ${customer.customerName}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Customer? value) {
                      setState(() {
                        selectedCustomer = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Product Dropdown
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Product (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: products.map((product) {
                      return DropdownMenuItem<Product>(
                        value: product,
                        child: Text(
                          '${product.productId} - ${product.productName}',
                        ),
                      );
                    }).toList(),
                    onChanged: (Product? value) {
                      setState(() {
                        selectedProduct = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Quantity
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  // Agreed Amount
                  TextField(
                    controller: agreedAmountController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Agreed Amount *',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (String? value) async {
                      if (value != null &&
                          value != selectedStatus &&
                          (value == 'completed' || value == 'cancelled')) {
                        // Validate payment before changing status
                        final paymentService = PaymentService();
                        final validation = await paymentService
                            .validatePaymentForEvent(customerEvent.eventNo);

                        if (!validation['hasPayments']) {
                          // No payment reference found
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('No Payment Reference Found'),
                              content: const Text(
                                'No payment records were found for this event. Are you sure you want to change the status?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes, Continue'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        } else if (!validation['isValid']) {
                          // Payment exists but not satisfied
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Payment Not Satisfied'),
                              content: Text(validation['message']),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes, Continue'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        } else {
                          // Payment is satisfied - just confirm
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Status Change'),
                              content: Text(
                                'Payment is satisfied. Do you want to change the status to ${value == 'completed' ? 'Completed' : 'Cancelled'}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Yes, Continue'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        }
                      } else {
                        setState(() {
                          selectedStatus = value ?? 'active';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Event Date
                  InkWell(
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
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Event Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Expected Finishing Date
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate:
                            selectedExpectedFinishingDate ??
                            DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedExpectedFinishingDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Expected Finishing Date (Optional)',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedExpectedFinishingDate != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    selectedExpectedFinishingDate = null;
                                  });
                                },
                              ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                      child: Text(
                        selectedExpectedFinishingDate != null
                            ? '${selectedExpectedFinishingDate!.day}/${selectedExpectedFinishingDate!.month}/${selectedExpectedFinishingDate!.year}'
                            : 'Tap to select date',
                        style: TextStyle(
                          color: selectedExpectedFinishingDate != null
                              ? null
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                    quantityController.text.isEmpty ||
                    agreedAmountController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate amount
                final agreedAmount = double.tryParse(
                  agreedAmountController.text,
                );
                if (agreedAmount == null || agreedAmount < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid agreed amount'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate quantity
                final quantity = double.tryParse(quantityController.text);
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final updatedCustomerEvent = CustomerEvent(
                  eventNo: customerEvent.eventNo,
                  eventName: eventNameController.text.trim(),
                  custId: selectedCustomer!.custId,
                  productId: selectedProduct?.productId ?? 'NONE',
                  customerName: selectedCustomer!.customerName,
                  quantity: quantity,
                  agreedAmount: agreedAmount,
                  eventDate: selectedDate,
                  expectedFinishingDate: selectedExpectedFinishingDate,
                  status: selectedStatus,
                );

                final success = await customerEventService.updateCustomerEvent(
                  updatedCustomerEvent,
                );

                if (success) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Customer Event "${updatedCustomerEvent.eventName}" updated successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Failed to update customer event. Please try again.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
