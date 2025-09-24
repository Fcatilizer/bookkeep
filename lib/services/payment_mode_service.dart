import 'package:sqflite/sqflite.dart';
import '../helpers/database_helper.dart';
import '../models/payment_mode.dart';

class PaymentModeService {
  static final PaymentModeService _instance = PaymentModeService._internal();
  factory PaymentModeService() => _instance;
  PaymentModeService._internal();

  Future<List<PaymentMode>> getAllPaymentModes() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_modes',
      orderBy: 'payment_mode_name ASC',
    );
    return List.generate(maps.length, (i) => PaymentMode.fromMap(maps[i]));
  }

  Future<List<PaymentMode>> getActivePaymentModes() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_modes',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'payment_mode_name ASC',
    );
    return List.generate(maps.length, (i) => PaymentMode.fromMap(maps[i]));
  }

  Future<PaymentMode?> getPaymentModeById(String paymentModeId) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_modes',
      where: 'payment_mode_id = ?',
      whereArgs: [paymentModeId],
    );
    if (maps.isNotEmpty) {
      return PaymentMode.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PaymentMode>> getPaymentModesByType(String type) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payment_modes',
      where: 'type = ? AND is_active = ?',
      whereArgs: [type, 1],
      orderBy: 'payment_mode_name ASC',
    );
    return List.generate(maps.length, (i) => PaymentMode.fromMap(maps[i]));
  }

  Future<int> createPaymentMode(PaymentMode paymentMode) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('payment_modes', paymentMode.toMap());
  }

  Future<int> updatePaymentMode(PaymentMode paymentMode) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'payment_modes',
      paymentMode.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'payment_mode_id = ?',
      whereArgs: [paymentMode.paymentModeId],
    );
  }

  Future<int> deletePaymentMode(String paymentModeId) async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'payment_modes',
      where: 'payment_mode_id = ?',
      whereArgs: [paymentModeId],
    );
  }

  Future<int> togglePaymentModeStatus(String paymentModeId) async {
    final paymentMode = await getPaymentModeById(paymentModeId);
    if (paymentMode != null) {
      return await updatePaymentMode(
        paymentMode.copyWith(isActive: !paymentMode.isActive),
      );
    }
    return 0;
  }

  Future<String> generatePaymentModeId() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM payment_modes',
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return 'PM${(count + 1).toString().padLeft(4, '0')}';
  }

  Future<bool> isPaymentModeNameExists(String name, {String? excludeId}) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause = 'LOWER(payment_mode_name) = ?';
    List<dynamic> whereArgs = [name.toLowerCase()];

    if (excludeId != null) {
      whereClause += ' AND payment_mode_id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      'payment_modes',
      where: whereClause,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
  }

  Future<Map<String, int>> getPaymentModeCountByType() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT type, COUNT(*) as count 
      FROM payment_modes 
      WHERE is_active = 1 
      GROUP BY type 
      ORDER BY type
    ''');

    final Map<String, int> counts = {};
    for (final row in result) {
      counts[row['type'] as String] = row['count'] as int;
    }
    return counts;
  }
}
