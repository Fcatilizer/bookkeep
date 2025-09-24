import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../helpers/database_helper.dart';

class DataPrivacyService {
  static const String backupFileExtension = '.bookkeep';

  /// Backup the entire database to a JSON file
  static Future<String> backupDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Get all data from all tables
      final customers = await db.query('customers');
      final products = await db.query('products');
      final customerEvents = await db.query('customer_events');
      final dailyEvents = await db.query('daily_events');

      // Create backup data structure
      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'tables': {
          'customers': customers,
          'products': products,
          'customer_events': customerEvents,
          'daily_events': dailyEvents,
        },
      };

      // Convert to JSON
      final jsonString = jsonEncode(backupData);

      // Get Documents directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'bookkeep_backup_$timestamp$backupFileExtension';
      final file = File('${directory.path}/$fileName');

      // Write backup file
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      throw Exception('Failed to backup database: $e');
    }
  }

  /// Restore the entire database from a backup file
  static Future<void> restoreDatabase() async {
    try {
      // Let user select backup file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        dialogTitle: 'Select BookKeep Backup File (.bookkeep)',
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No backup file selected');
      }

      final file = File(result.files.first.path!);
      if (!await file.exists()) {
        throw Exception('Backup file does not exist');
      }

      // Validate file extension
      if (!file.path.toLowerCase().endsWith(
        backupFileExtension.toLowerCase(),
      )) {
        throw Exception(
          'Invalid file type. Please select a .bookkeep backup file',
        );
      }

      // Read backup file
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate backup file structure
      if (!backupData.containsKey('tables')) {
        throw Exception('Invalid backup file format');
      }

      final tables = backupData['tables'] as Map<String, dynamic>;

      // Get database instance
      final db = await DatabaseHelper.instance.database;

      // Clear existing data and restore from backup
      await db.transaction((txn) async {
        // Delete all existing data (in order due to foreign key constraints)
        await txn.delete('daily_events');
        await txn.delete('customer_events');
        await txn.delete('products');
        await txn.delete('customers');

        // Restore customers
        if (tables.containsKey('customers')) {
          final customers = tables['customers'] as List<dynamic>;
          for (final customer in customers) {
            await txn.insert('customers', Map<String, dynamic>.from(customer));
          }
        }

        // Restore products
        if (tables.containsKey('products')) {
          final products = tables['products'] as List<dynamic>;
          for (final product in products) {
            await txn.insert('products', Map<String, dynamic>.from(product));
          }
        }

        // Restore customer_events
        if (tables.containsKey('customer_events')) {
          final customerEvents = tables['customer_events'] as List<dynamic>;
          for (final event in customerEvents) {
            await txn.insert(
              'customer_events',
              Map<String, dynamic>.from(event),
            );
          }
        }

        // Restore daily_events
        if (tables.containsKey('daily_events')) {
          final dailyEvents = tables['daily_events'] as List<dynamic>;
          for (final event in dailyEvents) {
            await txn.insert('daily_events', Map<String, dynamic>.from(event));
          }
        }
      });
    } catch (e) {
      throw Exception('Failed to restore database: $e');
    }
  }

  /// Wipe/Delete all data from the database
  static Future<void> wipeDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Delete all data in order due to foreign key constraints
      await db.transaction((txn) async {
        await txn.delete('daily_events');
        await txn.delete('customer_events');
        await txn.delete('products');
        await txn.delete('customers');
      });
    } catch (e) {
      throw Exception('Failed to wipe database: $e');
    }
  }

  /// Get database statistics for display
  static Future<Map<String, int>> getDatabaseStats() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final customerResult = await db.rawQuery(
        'SELECT COUNT(*) FROM customers',
      );
      final customerCount = customerResult.first.values.first as int? ?? 0;

      final productResult = await db.rawQuery('SELECT COUNT(*) FROM products');
      final productCount = productResult.first.values.first as int? ?? 0;

      final customerEventResult = await db.rawQuery(
        'SELECT COUNT(*) FROM customer_events',
      );
      final customerEventCount =
          customerEventResult.first.values.first as int? ?? 0;

      final dailyEventResult = await db.rawQuery(
        'SELECT COUNT(*) FROM daily_events',
      );
      final dailyEventCount = dailyEventResult.first.values.first as int? ?? 0;

      return {
        'customers': customerCount,
        'products': productCount,
        'customer_events': customerEventCount,
        'daily_events': dailyEventCount,
      };
    } catch (e) {
      return {
        'customers': 0,
        'products': 0,
        'customer_events': 0,
        'daily_events': 0,
      };
    }
  }
}
