// 🗄️ Database Helper - SQLite database management and initialization
//
// This class provides centralized database operations for the BookKeep application.
// It handles database creation, schema updates, cross-platform compatibility,
// and maintains database connections using the Singleton pattern.
//
// Author: Ashish Gaurav (@Fcatilizer)
// Created: 2025
// Last Updated: September 24, 2025

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// DatabaseHelper - Singleton class for SQLite database management
///
/// This class provides:
/// - Cross-platform SQLite database initialization (Mobile + Desktop)
/// - Database schema creation and version management
/// - Connection pooling and resource management
/// - Foreign key constraint enforcement
/// - Database migration handling
///
/// Database Schema:
/// - customers: Customer information and contacts
/// - products: Product/service definitions
/// - customer_events: Event/project management
/// - daily_events: Daily expense tracking
/// - payments: Payment transaction records
/// - expense_types: Expense category definitions
/// - payment_modes: Payment method configurations
class DatabaseHelper {
  /// Singleton instance for global database access
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// Database connection instance
  static Database? _database;

  /// Flag to prevent multiple platform initializations
  static bool _initialized = false;

  /// Private constructor for Singleton pattern
  DatabaseHelper._init();

  /// Get database instance with lazy initialization
  ///
  /// Returns existing connection or creates new one if needed.
  /// Handles platform-specific initialization for desktop support.
  ///
  /// Returns: Database instance ready for operations
  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize database factory for desktop platforms (only once)
    if (!_initialized) {
      _initializeDatabaseFactory();
      _initialized = true;
    }

    _database = await _initDB('bookkeep.db');
    return _database!;
  }

  /// Initialize platform-specific database factory
  ///
  /// Configures SQLite to work across different platforms:
  /// - Mobile (Android/iOS): Uses default SQLite implementation
  /// - Desktop (Windows/macOS/Linux): Uses FFI-based SQLite
  ///
  /// This ensures the app works consistently across all supported platforms.
  static void _initializeDatabaseFactory() {
    // Initialize the database factory for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      print('Initializing SQLite for desktop platform');
      // Initialize FFI
      sqfliteFfiInit();
      // Change the default factory
      databaseFactory = databaseFactoryFfi;
      print('SQLite desktop factory initialized');
    }
  }

  /// Initialize database with proper configuration
  ///
  /// Creates or opens the SQLite database file with:
  /// - Version management for schema updates
  /// - Foreign key constraint enforcement
  /// - Proper file path resolution
  ///
  /// [filePath] - Database filename
  /// Returns: Configured Database instance
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9, // Current schema version - increment for updates
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        // Enable foreign key constraints for referential integrity
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers(
        Cust_ID TEXT PRIMARY KEY,
        Customer_Name TEXT NOT NULL,
        Location TEXT,
        Contact_Person TEXT,
        Mobile_No TEXT,
        GST_No TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        Product_ID TEXT PRIMARY KEY,
        Product_Name TEXT NOT NULL,
        Tax_Rate REAL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE customer_events(
        Event_No TEXT PRIMARY KEY,
        Event_Name TEXT NOT NULL,
        Cust_ID TEXT NOT NULL,
        Product_ID TEXT NOT NULL,
        Customer_Name TEXT NOT NULL,
        Quantity REAL NOT NULL DEFAULT 1.0,
        Agreed_Amount REAL NOT NULL DEFAULT 0.0,
        Event_Date TEXT,
        Expected_Finishing_Date TEXT,
        Status TEXT DEFAULT 'active',
        FOREIGN KEY (Cust_ID) REFERENCES customers (Cust_ID) ON DELETE CASCADE,
        FOREIGN KEY (Product_ID) REFERENCES products (Product_ID) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_events(
        Event_No TEXT PRIMARY KEY,
        Event_Name TEXT NOT NULL,
        Cust_ID TEXT NOT NULL,
        Product_ID TEXT NOT NULL,
        Customer_Name TEXT NOT NULL,
        Expense_Type TEXT NOT NULL,
        Expense_Name TEXT NOT NULL,
        Amount REAL NOT NULL DEFAULT 0.0,
        Event_Date TEXT,
        Customer_Event_No TEXT,
        FOREIGN KEY (Cust_ID) REFERENCES customers (Cust_ID) ON DELETE CASCADE,
        FOREIGN KEY (Product_ID) REFERENCES products (Product_ID) ON DELETE CASCADE,
        FOREIGN KEY (Customer_Event_No) REFERENCES customer_events (Event_No) ON DELETE SET NULL
      )
    ''');

    // Create expense_types table
    await db.execute('''
      CREATE TABLE expense_types(
        expense_type_id TEXT PRIMARY KEY,
        expense_type_name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Create payment_modes table
    await db.execute('''
      CREATE TABLE payment_modes(
        payment_mode_id TEXT PRIMARY KEY,
        payment_mode_name TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Create payments table
    await db.execute('''
      CREATE TABLE payments(
        payment_id TEXT PRIMARY KEY,
        customer_event_no TEXT NOT NULL,
        paying_person_name TEXT NOT NULL,
        payment_type TEXT NOT NULL DEFAULT 'cash',
        amount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        reference TEXT,
        notes TEXT,
        payment_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (customer_event_no) REFERENCES customer_events (Event_No) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Fix the typo in column name from 'Cusstomer_Name' to 'Customer_Name'
      try {
        // Check if the table exists and has the old column name
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='customers'",
        );

        if (tables.isNotEmpty) {
          // Check if the old column exists
          final columns = await db.rawQuery("PRAGMA table_info(customers)");
          final hasOldColumn = columns.any(
            (col) => col['name'] == 'Cusstomer_Name',
          );

          if (hasOldColumn) {
            // Create new table with correct schema
            await db.execute('''
              CREATE TABLE customers_new(
                Cust_ID TEXT PRIMARY KEY,
                Customer_Name TEXT NOT NULL,
                Location TEXT,
                Contact_Person TEXT,
                Mobile_No TEXT,
                GST_No TEXT
              )
            ''');

            // Copy data from old table to new table
            await db.execute('''
              INSERT INTO customers_new (Cust_ID, Customer_Name, Location, Contact_Person, Mobile_No, GST_No)
              SELECT Cust_ID, Cusstomer_Name, Location, Contact_Person, Mobile_No, GST_No
              FROM customers
            ''');

            // Drop old table
            await db.execute('DROP TABLE customers');

            // Rename new table
            await db.execute('ALTER TABLE customers_new RENAME TO customers');
          }
        }
      } catch (e) {
        print('Migration error: $e');
        // If migration fails, recreate the table
        await db.execute('DROP TABLE IF EXISTS customers');
        await db.execute('''
          CREATE TABLE customers(
            Cust_ID TEXT PRIMARY KEY,
            Customer_Name TEXT NOT NULL,
            Location TEXT,
            Contact_Person TEXT,
            Mobile_No TEXT,
            GST_No TEXT
          )
        ''');
      }
    }

    if (oldVersion < 3) {
      // Add new tables for products and events
      try {
        // Drop old products table if it exists (had different schema)
        await db.execute('DROP TABLE IF EXISTS products');

        // Create new products table with correct schema
        await db.execute('''
          CREATE TABLE products(
            Product_ID TEXT PRIMARY KEY,
            Product_Name TEXT NOT NULL,
            Tax_Rate REAL DEFAULT 0.0
          )
        ''');

        // Create events table with foreign key relationships
        await db.execute('''
          CREATE TABLE events(
            Event_No TEXT PRIMARY KEY,
            Event_Name TEXT NOT NULL,
            Cust_ID TEXT NOT NULL,
            Product_ID TEXT NOT NULL,
            Customer_Name TEXT NOT NULL,
            Expense_Type TEXT NOT NULL,
            Expense_Name TEXT NOT NULL,
            Amount REAL NOT NULL DEFAULT 0.0,
            Event_Date TEXT,
            FOREIGN KEY (Cust_ID) REFERENCES customers (Cust_ID) ON DELETE CASCADE,
            FOREIGN KEY (Product_ID) REFERENCES products (Product_ID) ON DELETE CASCADE
          )
        ''');

        print('Successfully created products and events tables');
      } catch (e) {
        print('Error creating new tables: $e');
      }
    }

    if (oldVersion < 4) {
      // Separate events into customer_events and daily_events
      try {
        // Create customer_events table
        await db.execute('''
          CREATE TABLE customer_events(
            Event_No TEXT PRIMARY KEY,
            Event_Name TEXT NOT NULL,
            Cust_ID TEXT NOT NULL,
            Product_ID TEXT NOT NULL,
            Customer_Name TEXT NOT NULL,
            Expense_Type TEXT NOT NULL,
            Expense_Name TEXT NOT NULL,
            Agreed_Amount REAL NOT NULL DEFAULT 0.0,
            Event_Date TEXT,
            Status TEXT DEFAULT 'active',
            FOREIGN KEY (Cust_ID) REFERENCES customers (Cust_ID) ON DELETE CASCADE,
            FOREIGN KEY (Product_ID) REFERENCES products (Product_ID) ON DELETE CASCADE
          )
        ''');

        // Rename existing events table to daily_events and update schema
        await db.execute('ALTER TABLE events RENAME TO events_old');

        await db.execute('''
          CREATE TABLE daily_events(
            Event_No TEXT PRIMARY KEY,
            Event_Name TEXT NOT NULL,
            Cust_ID TEXT NOT NULL,
            Product_ID TEXT NOT NULL,
            Customer_Name TEXT NOT NULL,
            Expense_Type TEXT NOT NULL,
            Expense_Name TEXT NOT NULL,
            Amount REAL NOT NULL DEFAULT 0.0,
            Event_Date TEXT,
            Customer_Event_No TEXT,
            FOREIGN KEY (Cust_ID) REFERENCES customers (Cust_ID) ON DELETE CASCADE,
            FOREIGN KEY (Product_ID) REFERENCES products (Product_ID) ON DELETE CASCADE,
            FOREIGN KEY (Customer_Event_No) REFERENCES customer_events (Event_No) ON DELETE SET NULL
          )
        ''');

        // Copy data from old events table to daily_events
        await db.execute('''
          INSERT INTO daily_events (Event_No, Event_Name, Cust_ID, Product_ID, Customer_Name, Expense_Type, Expense_Name, Amount, Event_Date)
          SELECT Event_No, Event_Name, Cust_ID, Product_ID, Customer_Name, Expense_Type, Expense_Name, Amount, Event_Date
          FROM events_old
        ''');

        // Drop old table
        await db.execute('DROP TABLE events_old');

        print(
          'Successfully separated events into customer_events and daily_events',
        );
      } catch (e) {
        print('Error separating events tables: $e');
      }
    }

    // Version 5: Update customer_events table to replace Expense_Type and Expense_Name with Quantity
    if (oldVersion < 5) {
      print('Upgrading database to version 5...');
      try {
        // Rename existing table
        await db.execute(
          'ALTER TABLE customer_events RENAME TO customer_events_old',
        );

        // Create new table with updated schema
        await db.execute('''
          CREATE TABLE customer_events(
            Event_No TEXT PRIMARY KEY,
            Event_Name TEXT NOT NULL,
            Cust_ID TEXT NOT NULL,
            Product_ID TEXT NOT NULL,
            Customer_Name TEXT NOT NULL,
            Quantity REAL NOT NULL DEFAULT 1.0,
            Agreed_Amount REAL NOT NULL DEFAULT 0.0,
            Event_Date TEXT,
            Status TEXT DEFAULT 'active',
            FOREIGN KEY (Cust_ID) REFERENCES customers (Cust_ID) ON DELETE CASCADE,
            FOREIGN KEY (Product_ID) REFERENCES products (Product_ID) ON DELETE CASCADE
          )
        ''');

        // Copy data from old table to new table with default quantity of 1.0
        await db.execute('''
          INSERT INTO customer_events (Event_No, Event_Name, Cust_ID, Product_ID, Customer_Name, Quantity, Agreed_Amount, Event_Date, Status)
          SELECT Event_No, Event_Name, Cust_ID, Product_ID, Customer_Name, 1.0, Agreed_Amount, Event_Date, Status
          FROM customer_events_old
        ''');

        // Drop old table
        await db.execute('DROP TABLE customer_events_old');

        print('Successfully updated customer_events table with Quantity field');
      } catch (e) {
        print('Error updating customer_events table: $e');
      }
    }

    // Version 6: Add Expected_Finishing_Date column to customer_events table
    if (oldVersion < 6) {
      print('Upgrading database to version 6...');
      try {
        // Add the Expected_Finishing_Date column to existing customer_events table
        await db.execute('''
          ALTER TABLE customer_events ADD COLUMN Expected_Finishing_Date TEXT
        ''');

        print(
          'Successfully added Expected_Finishing_Date column to customer_events table',
        );
      } catch (e) {
        print('Error adding Expected_Finishing_Date column: $e');
      }
    }

    // Version 7: Add expense_types and payment_modes tables
    if (oldVersion < 7) {
      print('Upgrading database to version 7...');
      try {
        // Create expense_types table
        await db.execute('''
          CREATE TABLE expense_types(
            expense_type_id TEXT PRIMARY KEY,
            expense_type_name TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        // Create payment_modes table
        await db.execute('''
          CREATE TABLE payment_modes(
            payment_mode_id TEXT PRIMARY KEY,
            payment_mode_name TEXT NOT NULL,
            type TEXT NOT NULL,
            description TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        print('Successfully created expense_types and payment_modes tables');
      } catch (e) {
        print('Error creating expense_types and payment_modes tables: $e');
      }
    }

    // Version 8: Add payments table
    if (oldVersion < 8) {
      print('Upgrading database to version 8...');
      try {
        // Create payments table
        await db.execute('''
          CREATE TABLE payments(
            payment_id TEXT PRIMARY KEY,
            customer_event_no TEXT NOT NULL,
            payment_mode_id TEXT NOT NULL,
            amount REAL NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            reference TEXT,
            notes TEXT,
            payment_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (customer_event_no) REFERENCES customer_events (Event_No) ON DELETE CASCADE,
            FOREIGN KEY (payment_mode_id) REFERENCES payment_modes (payment_mode_id) ON DELETE RESTRICT
          )
        ''');

        print('Successfully created payments table');
      } catch (e) {
        print('Error creating payments table: $e');
      }
    }

    // Version 9: Update payments table structure
    if (oldVersion < 9) {
      print('Upgrading database to version 9...');
      try {
        // Create new payments table with updated structure
        await db.execute('''
          CREATE TABLE payments_new(
            payment_id TEXT PRIMARY KEY,
            customer_event_no TEXT NOT NULL,
            paying_person_name TEXT NOT NULL,
            payment_type TEXT NOT NULL DEFAULT 'cash',
            amount REAL NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            reference TEXT,
            notes TEXT,
            payment_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY (customer_event_no) REFERENCES customer_events (Event_No) ON DELETE CASCADE
          )
        ''');

        // Migrate existing data if payments table exists
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='payments'",
        );

        if (tables.isNotEmpty) {
          // Copy existing data, providing default values for new fields
          await db.execute('''
            INSERT INTO payments_new (
              payment_id, customer_event_no, paying_person_name, payment_type,
              amount, status, reference, notes, payment_date, created_at, updated_at
            )
            SELECT 
              payment_id, customer_event_no, 'Unknown' as paying_person_name, 'cash' as payment_type,
              amount, status, reference, notes, payment_date, created_at, updated_at
            FROM payments
          ''');

          // Drop old table
          await db.execute('DROP TABLE payments');
        }

        // Rename new table
        await db.execute('ALTER TABLE payments_new RENAME TO payments');

        print('Successfully updated payments table structure');
      } catch (e) {
        print('Error updating payments table: $e');
      }
    }
  }

  // Customer CRUD operations
  Future<int> insertCustomer(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('customers', row);
  }

  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final db = await instance.database;
    return await db.query('customers');
  }

  Future<int> updateCustomer(String custId, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      row,
      where: 'Cust_ID = ?',
      whereArgs: [custId],
    );
  }

  Future<int> deleteCustomer(String custId) async {
    final db = await instance.database;
    return await db.delete(
      'customers',
      where: 'Cust_ID = ?',
      whereArgs: [custId],
    );
  }

  // Product CRUD operations
  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    final db = await instance.database;
    return await db.query('products');
  }

  Future<int> updateProduct(String productId, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'products',
      row,
      where: 'Product_ID = ?',
      whereArgs: [productId],
    );
  }

  Future<int> deleteProduct(String productId) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'Product_ID = ?',
      whereArgs: [productId],
    );
  }

  // Customer Event CRUD operations
  Future<int> insertCustomerEvent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('customer_events', row);
  }

  Future<List<Map<String, dynamic>>> fetchCustomerEvents() async {
    final db = await instance.database;
    return await db.query('customer_events');
  }

  Future<List<Map<String, dynamic>>> fetchCustomerEventsByCustomer(
    String custId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'customer_events',
      where: 'Cust_ID = ?',
      whereArgs: [custId],
    );
  }

  Future<int> updateCustomerEvent(
    String eventNo,
    Map<String, dynamic> row,
  ) async {
    final db = await instance.database;
    return await db.update(
      'customer_events',
      row,
      where: 'Event_No = ?',
      whereArgs: [eventNo],
    );
  }

  Future<int> deleteCustomerEvent(String eventNo) async {
    final db = await instance.database;
    return await db.delete(
      'customer_events',
      where: 'Event_No = ?',
      whereArgs: [eventNo],
    );
  }

  // Clean up orphaned payment records
  Future<int> cleanupOrphanedPayments() async {
    final db = await instance.database;
    return await db.rawDelete('''
      DELETE FROM payments 
      WHERE customer_event_no NOT IN (
        SELECT Event_No FROM customer_events
      )
    ''');
  }

  // Daily Event CRUD operations
  Future<int> insertDailyEvent(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('daily_events', row);
  }

  Future<List<Map<String, dynamic>>> fetchDailyEvents() async {
    final db = await instance.database;
    return await db.query('daily_events');
  }

  Future<List<Map<String, dynamic>>> fetchDailyEventsByCustomer(
    String custId,
  ) async {
    final db = await instance.database;
    return await db.query(
      'daily_events',
      where: 'Cust_ID = ?',
      whereArgs: [custId],
    );
  }

  Future<List<Map<String, dynamic>>> fetchDailyEventsByCustomerEvent(
    String customerEventNo,
  ) async {
    final db = await instance.database;
    return await db.query(
      'daily_events',
      where: 'Customer_Event_No = ?',
      whereArgs: [customerEventNo],
    );
  }

  Future<int> updateDailyEvent(String eventNo, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'daily_events',
      row,
      where: 'Event_No = ?',
      whereArgs: [eventNo],
    );
  }

  Future<int> deleteDailyEvent(String eventNo) async {
    final db = await instance.database;
    return await db.delete(
      'daily_events',
      where: 'Event_No = ?',
      whereArgs: [eventNo],
    );
  }

  // Utility methods for ID checking and generation
  Future<bool> customerExists(String custId) async {
    final db = await instance.database;
    final result = await db.query(
      'customers',
      where: 'Cust_ID = ?',
      whereArgs: [custId],
    );
    return result.isNotEmpty;
  }

  Future<bool> productExists(String productId) async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'Product_ID = ?',
      whereArgs: [productId],
    );
    return result.isNotEmpty;
  }

  Future<bool> customerEventExists(String eventNo) async {
    final db = await instance.database;
    final result = await db.query(
      'customer_events',
      where: 'Event_No = ?',
      whereArgs: [eventNo],
    );
    return result.isNotEmpty;
  }

  Future<bool> dailyEventExists(String eventNo) async {
    final db = await instance.database;
    final result = await db.query(
      'daily_events',
      where: 'Event_No = ?',
      whereArgs: [eventNo],
    );
    return result.isNotEmpty;
  }

  // Get total daily activity amount for a customer event
  Future<double> getTotalDailyEventsForCustomerEvent(
    String customerEventNo,
  ) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(Amount) as total FROM daily_events WHERE Customer_Event_No = ?',
      [customerEventNo],
    );
    return (result.first['total'] as double?) ?? 0.0;
  }

  // Close
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
