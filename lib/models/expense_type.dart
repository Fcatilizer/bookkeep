// 📊 Expense Type Model - Category management for expense classification
//
// This model defines expense categories used throughout the application
// for organizing and categorizing different types of expenses and costs.
//
// Author: Ashish Gaurav (@Fcatilizer)
// Created: 2025
// Last Updated: September 24, 2025

/// ExpenseType Model - Represents an expense category definition
///
/// This class manages expense type configurations that are used to:
/// - Categorize different types of expenses
/// - Control active/inactive status for expense types
/// - Provide hierarchical organization through categories
/// - Maintain audit trail for expense type changes
///
/// Usage Examples:
/// - Office Supplies (category: Administrative)
/// - Marketing Costs (category: Business Development)
/// - Travel Expenses (category: Operations)
class ExpenseType {
  /// Unique identifier for the expense type
  final String expenseTypeId;

  /// Display name of the expense type
  final String expenseTypeName;

  /// Category this expense type belongs to (for grouping)
  final String category;

  /// Optional detailed description of the expense type
  final String? description;

  /// Whether this expense type is currently active and available for use
  final bool isActive;

  /// Timestamp when this expense type was created
  final DateTime createdAt;

  /// Timestamp of the last update to this expense type
  final DateTime? updatedAt;

  /// Constructor for creating a new ExpenseType instance
  ///
  /// [isActive] defaults to true for new expense types.
  /// [description] and [updatedAt] are optional fields.
  ExpenseType({
    required this.expenseTypeId,
    required this.expenseTypeName,
    required this.category,
    this.description,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create ExpenseType from database map
  ///
  /// Converts SQLite query results into ExpenseType objects.
  /// Handles the conversion of integer is_active field to boolean.
  ///
  /// [map] - Database row as Map<String, dynamic>
  /// Returns: New ExpenseType instance with data from map
  factory ExpenseType.fromMap(Map<String, dynamic> map) {
    return ExpenseType(
      expenseTypeId: map['expense_type_id'] ?? '',
      expenseTypeName: map['expense_type_name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'],
      isActive: (map['is_active'] ?? 1) == 1,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// Convert ExpenseType to database map format
  ///
  /// Transforms the object into a Map suitable for SQLite operations.
  /// Boolean isActive is converted to integer (1 = true, 0 = false).
  ///
  /// Returns: Map ready for database insertion/update
  Map<String, dynamic> toMap() {
    return {
      'expense_type_id': expenseTypeId,
      'expense_type_name': expenseTypeName,
      'category': category,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of this ExpenseType with specified fields updated
  ///
  /// Useful for updating expense types while maintaining immutability.
  /// Commonly used when toggling active status or updating category info.
  ///
  /// Example:
  /// ```dart
  /// final deactivated = expenseType.copyWith(
  ///   isActive: false,
  ///   updatedAt: DateTime.now(),
  /// );
  /// ```
  ///
  /// Returns: New ExpenseType instance with updated fields
  ExpenseType copyWith({
    String? expenseTypeId,
    String? expenseTypeName,
    String? category,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseType(
      expenseTypeId: expenseTypeId ?? this.expenseTypeId,
      expenseTypeName: expenseTypeName ?? this.expenseTypeName,
      category: category ?? this.category,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
