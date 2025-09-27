import '../helpers/database_helper.dart';
import '../models/customer_event.dart';

class CustomerEventService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Create a new customer event
  Future<bool> createCustomerEvent(CustomerEvent event) async {
    try {
      print(
        'Attempting to create customer event: ${event.eventNo} - ${event.eventName}',
      );
      final result = await _databaseHelper.insertCustomerEvent(event.toMap());
      print('Customer event created successfully with result: $result');
      return result > 0;
    } catch (e) {
      print('Error creating customer event: $e');
      return false;
    }
  }

  // Get all customer events
  Future<List<CustomerEvent>> getAllCustomerEvents() async {
    try {
      final eventMaps = await _databaseHelper.fetchCustomerEvents();
      return eventMaps.map((map) => CustomerEvent.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching customer events: $e');
      return [];
    }
  }

  // Get customer event by Event No
  Future<CustomerEvent?> getCustomerEventByNo(String eventNo) async {
    try {
      final db = await _databaseHelper.database;
      final eventMaps = await db.query(
        'customer_events',
        where: 'Event_No = ?',
        whereArgs: [eventNo],
      );

      if (eventMaps.isNotEmpty) {
        return CustomerEvent.fromMap(eventMaps.first);
      }
      return null;
    } catch (e) {
      print('Error fetching customer event by No: $e');
      return null;
    }
  }

  // Get customer events by customer ID
  Future<List<CustomerEvent>> getCustomerEventsByCustomer(String custId) async {
    try {
      final eventMaps = await _databaseHelper.fetchCustomerEventsByCustomer(
        custId,
      );
      return eventMaps.map((map) => CustomerEvent.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching customer events by customer: $e');
      return [];
    }
  }

  // Update customer event
  Future<bool> updateCustomerEvent(CustomerEvent event) async {
    try {
      final result = await _databaseHelper.updateCustomerEvent(
        event.eventNo,
        event.toMap(),
      );
      return result > 0;
    } catch (e) {
      print('Error updating customer event: $e');
      return false;
    }
  }

  // Delete customer event
  Future<bool> deleteCustomerEvent(String eventNo) async {
    try {
      final result = await _databaseHelper.deleteCustomerEvent(eventNo);
      return result > 0;
    } catch (e) {
      print('Error deleting customer event: $e');
      return false;
    }
  }

  // Search customer events by name
  Future<List<CustomerEvent>> searchCustomerEventsByName(
    String searchTerm,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final eventMaps = await db.query(
        'customer_events',
        where: 'Event_Name LIKE ? OR Expense_Name LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      );
      return eventMaps.map((map) => CustomerEvent.fromMap(map)).toList();
    } catch (e) {
      print('Error searching customer events: $e');
      return [];
    }
  }

  // Get customer events by status
  Future<List<CustomerEvent>> getCustomerEventsByStatus(String status) async {
    try {
      final db = await _databaseHelper.database;
      final eventMaps = await db.query(
        'customer_events',
        where: 'Status = ?',
        whereArgs: [status],
      );
      return eventMaps.map((map) => CustomerEvent.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching customer events by status: $e');
      return [];
    }
  }

  // Generate unique customer event number
  Future<String> generateCustomerEventNo() async {
    try {
      final db = await _databaseHelper.database;

      // Get the highest existing customer event number
      final result = await db.rawQuery('''
        SELECT Event_No FROM customer_events 
        WHERE Event_No LIKE 'CE%' 
        ORDER BY CAST(SUBSTR(Event_No, 3) AS INTEGER) DESC 
        LIMIT 1
      ''');

      int nextNumber = 1;
      if (result.isNotEmpty) {
        final lastId = result.first['Event_No'] as String;
        final numberPart = lastId.substring(2); // Remove 'CE' prefix
        nextNumber = (int.tryParse(numberPart) ?? 0) + 1;
      }

      // Ensure we don't have a duplicate by checking if the generated ID exists
      String candidateId;
      do {
        candidateId = 'CE${nextNumber.toString().padLeft(4, '0')}';
        final existingEvent = await getCustomerEventByNo(candidateId);
        if (existingEvent == null) {
          break; // ID is unique
        }
        nextNumber++;
      } while (true);

      return candidateId;
    } catch (e) {
      print('Error generating customer event number: $e');
      return 'CE0001'; // fallback
    }
  }

  // Check if customer event exists
  Future<bool> customerEventExists(String eventNo) async {
    try {
      return await _databaseHelper.customerEventExists(eventNo);
    } catch (e) {
      print('Error checking if customer event exists: $e');
      return false;
    }
  }

  // Get total agreed amount for customer
  Future<double> getTotalAgreedAmountForCustomer(String custId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(Agreed_Amount) as total FROM customer_events WHERE Cust_ID = ? AND Status = ?',
        [custId, 'active'],
      );
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      print('Error getting total agreed amount for customer: $e');
      return 0.0;
    }
  }

  // Get customer events with daily expense totals
  Future<List<Map<String, dynamic>>> getCustomerEventsWithTotals() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          ce.*,
          COALESCE(SUM(de.Amount), 0.0) as daily_total
        FROM customer_events ce
        LEFT JOIN daily_events de ON ce.Event_No = de.Customer_Event_No
        GROUP BY ce.Event_No
        ORDER BY ce.Event_Date DESC, ce.Event_No DESC
      ''');
      return result;
    } catch (e) {
      print('Error getting customer events with totals: $e');
      return [];
    }
  }

  // Get daily expense for a specific customer event
  Future<List<Map<String, dynamic>>> getDailyEventsForCustomerEvent(
    String customerEventNo,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        '''
        SELECT 
          Event_No,
          Event_Name,
          Expense_Name,
          Amount,
          Event_Date
        FROM daily_events 
        WHERE Customer_Event_No = ?
        ORDER BY Event_Date DESC, Event_No DESC
      ''',
        [customerEventNo],
      );
      return result;
    } catch (e) {
      print('Error getting daily expense for customer event: $e');
      return [];
    }
  }
}
