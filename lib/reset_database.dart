// Script to reset database for testing
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  try {
    // Get the database path
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bookkeep.db');

    // Delete the existing database file
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      print('Existing database deleted: $path');
    } else {
      print('No existing database found at: $path');
    }

    print(
      'Database reset complete. The app will create a new database with the correct schema.',
    );
  } catch (e) {
    print('Error resetting database: $e');
  }
}
