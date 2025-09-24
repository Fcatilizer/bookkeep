// 💳 Payment Dialog Helper - UI dialog for payment creation and editing
//
// This helper provides a comprehensive dialog interface for managing payments.
// It includes form validation, customer event integration, payment type selection,
// and handles both creation of new payments and editing existing ones.
//
// Author: Ashish Gaurav (@Fcatilizer)
// Created: 2025
// Last Updated: September 24, 2025

import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../models/customer_event.dart';
import '../services/payment_service.dart';
import '../services/customer_event_service.dart';

/// Display payment creation/editing dialog
///
/// This function creates and shows a modal dialog for adding new payments
/// or editing existing ones. It provides:
/// - Customer event selection and validation
/// - Payment type and status selection using supported types from Payment model
/// - Date picker for payment date selection
/// - Form validation and error handling
/// - Automatic payment ID generation
///
/// [context] - Build context for dialog display
/// [payment] - Optional existing payment for editing (null for new payment)
void showAddPaymentDialog(BuildContext context, {Payment? payment}) async {
  final paymentService = PaymentService();
  final customerEventService = CustomerEventService();

  // Controllers
  final payingPersonController = TextEditingController(
    text: payment?.payingPersonName ?? '',
  );
  final amountController = TextEditingController(
    text: payment?.amount.toString() ?? '',
  );
  final referenceController = TextEditingController(
    text: payment?.reference ?? '',
  );
  final notesController = TextEditingController(text: payment?.notes ?? '');

  // State variables
  CustomerEvent? selectedCustomerEvent;
  String selectedPaymentType = payment?.paymentType ?? 'cash';
  String selectedStatus = payment?.status ?? 'pending';
  DateTime selectedDate = payment?.paymentDate ?? DateTime.now();

  // Generate payment ID
  String generatedPaymentId =
      payment?.paymentId ?? 'PAY${DateTime.now().millisecondsSinceEpoch}';

  // Get customer events
  List<CustomerEvent> customerEvents = [];
  try {
    customerEvents = await customerEventService.getAllCustomerEvents();
    if (payment != null) {
      selectedCustomerEvent = customerEvents.firstWhere(
        (ce) => ce.eventNo == payment.customerEventNo,
        orElse: () => customerEvents.isNotEmpty
            ? customerEvents.first
            : CustomerEvent(
                eventNo: '',
                eventName: '',
                custId: '',
                productId: '',
                customerName: '',
                quantity: 0.0,
                agreedAmount: 0.0,
              ),
      );
    }
  } catch (e) {
    customerEvents = [];
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(payment == null ? 'Add New Payment' : 'Edit Payment'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Payment ID Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
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
                        'Payment ID (Auto-generated)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        generatedPaymentId,
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

                // Customer Event Dropdown
                DropdownButtonFormField<CustomerEvent>(
                  value: selectedCustomerEvent,
                  decoration: const InputDecoration(
                    labelText: 'Customer Event *',
                    border: OutlineInputBorder(),
                  ),
                  items: customerEvents.map((CustomerEvent event) {
                    return DropdownMenuItem<CustomerEvent>(
                      value: event,
                      child: Text('${event.customerName} - ${event.eventName}'),
                    );
                  }).toList(),
                  onChanged: (CustomerEvent? newValue) {
                    setState(() {
                      selectedCustomerEvent = newValue;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Paying Person Name
                TextFormField(
                  controller: payingPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Paying Person Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Type
                DropdownButtonFormField<String>(
                  value: selectedPaymentType,
                  decoration: const InputDecoration(
                    labelText: 'Payment Type',
                    border: OutlineInputBorder(),
                  ),
                  items: Payment.paymentTypes.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(Payment.getPaymentTypeDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPaymentType = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount *',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Status
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['pending', 'partial', 'full'].map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Reference
                TextFormField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Transaction ID, cheque number, etc.',
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Additional notes about this payment',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Payment Date
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Change'),
                    ),
                  ],
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
              final amountText = amountController.text.trim();

              // Validation
              if (selectedCustomerEvent == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select a customer event'),
                  ),
                );
                return;
              }

              final payingPersonName = payingPersonController.text.trim();
              if (payingPersonName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter paying person name'),
                  ),
                );
                return;
              }

              final amount = double.tryParse(amountText);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount greater than 0'),
                  ),
                );
                return;
              }

              final newPayment = Payment(
                paymentId: generatedPaymentId,
                customerEventNo: selectedCustomerEvent!.eventNo,
                payingPersonName: payingPersonName,
                paymentType: selectedPaymentType,
                amount: amount,
                status: selectedStatus,
                reference: referenceController.text.trim().isNotEmpty
                    ? referenceController.text.trim()
                    : null,
                notes: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : null,
                paymentDate: selectedDate,
                createdAt: payment?.createdAt ?? DateTime.now(),
                updatedAt: payment != null ? DateTime.now() : null,
              );

              try {
                final bool success;
                if (payment == null) {
                  // Create new payment
                  success = await paymentService.createPayment(newPayment);
                } else {
                  // Update existing payment
                  success = await paymentService.updatePayment(newPayment);
                }

                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          payment == null
                              ? 'Payment of ₹${amount.toStringAsFixed(2)} by $payingPersonName recorded successfully!'
                              : 'Payment of ₹${amount.toStringAsFixed(2)} by $payingPersonName updated successfully!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          payment == null
                              ? 'Failed to record payment. Please try again.'
                              : 'Failed to update payment. Please try again.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(payment == null ? 'Record Payment' : 'Update Payment'),
          ),
        ],
      ),
    ),
  );
}
