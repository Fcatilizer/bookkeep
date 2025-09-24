import 'package:flutter/material.dart';
import '../models/payment_mode.dart';
import '../services/payment_mode_service.dart';

class PaymentModeDialog extends StatefulWidget {
  final PaymentMode? paymentMode; // null for add, existing for edit

  const PaymentModeDialog({Key? key, this.paymentMode}) : super(key: key);

  @override
  State<PaymentModeDialog> createState() => _PaymentModeDialogState();
}

class _PaymentModeDialogState extends State<PaymentModeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paymentModeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PaymentModeService _paymentModeService = PaymentModeService();

  String _selectedType = 'cash';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.paymentMode != null) {
      _paymentModeNameController.text = widget.paymentMode!.paymentModeName;
      _selectedType = widget.paymentMode!.type;
      _descriptionController.text = widget.paymentMode!.description ?? '';
      _isActive = widget.paymentMode!.isActive;
    }
  }

  @override
  void dispose() {
    _paymentModeNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  IconData _getTypeIcon(String type) {
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
      case 'other':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'bank_transfer':
        return Colors.purple;
      case 'upi':
        return Colors.orange;
      case 'cheque':
        return Colors.brown;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _savePaymentMode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _paymentModeNameController.text.trim();

      // Check for duplicate names
      final isDuplicate = await _paymentModeService.isPaymentModeNameExists(
        name,
        excludeId: widget.paymentMode?.paymentModeId,
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment mode name already exists')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (widget.paymentMode == null) {
        // Add new payment mode
        final paymentModeId = await _paymentModeService.generatePaymentModeId();
        final paymentMode = PaymentMode(
          paymentModeId: paymentModeId,
          paymentModeName: name,
          type: _selectedType,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await _paymentModeService.createPaymentMode(paymentMode);
      } else {
        // Update existing payment mode
        final updatedPaymentMode = widget.paymentMode!.copyWith(
          paymentModeName: name,
          type: _selectedType,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
        );
        await _paymentModeService.updatePaymentMode(updatedPaymentMode);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.paymentMode == null
                  ? 'Payment mode added successfully'
                  : 'Payment mode updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving payment mode: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.paymentMode == null
                      ? 'Add Payment Mode'
                      : 'Edit Payment Mode',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Mode Name
                TextFormField(
                  controller: _paymentModeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter payment mode name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Payment Type
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Type *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PaymentMode.paymentTypes.map((type) {
                        final isSelected = _selectedType == type;
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTypeIcon(type),
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : _getTypeColor(type),
                              ),
                              const SizedBox(width: 4),
                              Text(PaymentMode.getTypeDisplayName(type)),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedType = type);
                            }
                          },
                          backgroundColor: _getTypeColor(type).withOpacity(0.1),
                          selectedColor: _getTypeColor(type),
                          checkmarkColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Active Status
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: Text(_isActive ? 'Available for use' : 'Inactive'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePaymentMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FAADB),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.paymentMode == null ? 'Add' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
