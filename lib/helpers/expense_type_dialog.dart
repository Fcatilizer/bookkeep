import 'package:flutter/material.dart';
import '../models/expense_type.dart';
import '../services/expense_type_service.dart';

class ExpenseTypeDialog extends StatefulWidget {
  final ExpenseType? expenseType; // null for add, existing for edit

  const ExpenseTypeDialog({Key? key, this.expenseType}) : super(key: key);

  @override
  State<ExpenseTypeDialog> createState() => _ExpenseTypeDialogState();
}

class _ExpenseTypeDialogState extends State<ExpenseTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _expenseTypeNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ExpenseTypeService _expenseTypeService = ExpenseTypeService();

  List<String> _existingCategories = [];
  String? _selectedCategory;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.expenseType != null) {
      _expenseTypeNameController.text = widget.expenseType!.expenseTypeName;
      _categoryController.text = widget.expenseType!.category;
      _descriptionController.text = widget.expenseType!.description ?? '';
      _selectedCategory = widget.expenseType!.category;
      _isActive = widget.expenseType!.isActive;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _expenseTypeService.getExpenseCategories();
      setState(() {
        _existingCategories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading categories: $e')));
      }
    }
  }

  @override
  void dispose() {
    _expenseTypeNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveExpenseType() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _expenseTypeNameController.text.trim();

      // Check for duplicate names
      final isDuplicate = await _expenseTypeService.isExpenseTypeNameExists(
        name,
        excludeId: widget.expenseType?.expenseTypeId,
      );

      if (isDuplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense type name already exists')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final category = _selectedCategory ?? _categoryController.text.trim();

      if (widget.expenseType == null) {
        // Add new expense type
        final expenseTypeId = await _expenseTypeService.generateExpenseTypeId();
        final expenseType = ExpenseType(
          expenseTypeId: expenseTypeId,
          expenseTypeName: name,
          category: category,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
          createdAt: DateTime.now(),
        );
        await _expenseTypeService.createExpenseType(expenseType);
      } else {
        // Update existing expense type
        final updatedExpenseType = widget.expenseType!.copyWith(
          expenseTypeName: name,
          category: category,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          isActive: _isActive,
        );
        await _expenseTypeService.updateExpenseType(updatedExpenseType);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.expenseType == null
                  ? 'Expense type added successfully'
                  : 'Expense type updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense type: $e')),
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
                  widget.expenseType == null
                      ? 'Add Expense Type'
                      : 'Edit Expense Type',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Expense Type Name
                TextFormField(
                  controller: _expenseTypeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Type Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter expense type name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_existingCategories.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select or enter category',
                        ),
                        items: [
                          ..._existingCategories.map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: null,
                            child: Text('+ Add new category'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value;
                            if (value != null) {
                              _categoryController.text = value;
                            }
                          });
                        },
                      ),
                      if (_selectedCategory == null) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(
                            labelText: 'New Category Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (_selectedCategory == null &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter category name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ] else ...[
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter category name';
                          }
                          return null;
                        },
                      ),
                    ],
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
                      onPressed: _isLoading ? null : _saveExpenseType,
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
                          : Text(widget.expenseType == null ? 'Add' : 'Update'),
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
