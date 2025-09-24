import 'package:sqflite/sqflite.dart';
import '../helpers/database_helper.dart';
import '../models/expense_type.dart';

class ExpenseTypeService {
  static final ExpenseTypeService _instance = ExpenseTypeService._internal();
  factory ExpenseTypeService() => _instance;
  ExpenseTypeService._internal();

  Future<List<ExpenseType>> getAllExpenseTypes() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_types',
      orderBy: 'expense_type_name ASC',
    );
    return List.generate(maps.length, (i) => ExpenseType.fromMap(maps[i]));
  }

  Future<List<ExpenseType>> getActiveExpenseTypes() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_types',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'expense_type_name ASC',
    );
    return List.generate(maps.length, (i) => ExpenseType.fromMap(maps[i]));
  }

  Future<ExpenseType?> getExpenseTypeById(String expenseTypeId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expense_types',
      where: 'expense_type_id = ?',
      whereArgs: [expenseTypeId],
    );
    if (maps.isNotEmpty) {
      return ExpenseType.fromMap(maps.first);
    }
    return null;
  }

  Future<List<String>> getExpenseCategories() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM expense_types WHERE is_active = 1 ORDER BY category ASC',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  Future<int> createExpenseType(ExpenseType expenseType) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('expense_types', expenseType.toMap());
  }

  Future<int> updateExpenseType(ExpenseType expenseType) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'expense_types',
      expenseType.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'expense_type_id = ?',
      whereArgs: [expenseType.expenseTypeId],
    );
  }

  Future<int> deleteExpenseType(String expenseTypeId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'expense_types',
      where: 'expense_type_id = ?',
      whereArgs: [expenseTypeId],
    );
  }

  Future<int> toggleExpenseTypeStatus(String expenseTypeId) async {
    final expenseType = await getExpenseTypeById(expenseTypeId);
    if (expenseType != null) {
      return await updateExpenseType(
        expenseType.copyWith(isActive: !expenseType.isActive),
      );
    }
    return 0;
  }

  Future<String> generateExpenseTypeId() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expense_types',
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return 'EXT${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<bool> isExpenseTypeNameExists(String name, {String? excludeId}) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause = 'LOWER(expense_type_name) = ?';
    List<dynamic> whereArgs = [name.toLowerCase()];

    if (excludeId != null) {
      whereClause += ' AND expense_type_id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      'expense_types',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
  }
}
