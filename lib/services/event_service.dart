import '../helpers/database_helper.dart';
import '../models/event.dart';

class EventService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Create a new event
  Future<bool> createEvent(Event event) async {
    try {
      print(
        'Attempting to create event: ${event.eventNo} - ${event.eventName}',
      );
      final result = await _databaseHelper.insertDailyEvent(event.toMap());
      print('Event created successfully with result: $result');
      return result > 0; // Return true only if a row was actually inserted
    } catch (e) {
      print('Error creating event: $e');
      print('Event data: ${event.toMap()}');
      return false;
    }
  }

  // Get all events
  Future<List<Event>> getAllEvents() async {
    try {
      final eventMaps = await _databaseHelper.fetchDailyEvents();
      return eventMaps.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  // Get event by Event No
  Future<Event?> getEventByNo(String eventNo) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'daily_events',
        where: 'event_no = ?',
        whereArgs: [eventNo],
      );

      if (result.isNotEmpty) {
        return Event.fromMap(result.first);
      }
      return null;
    } catch (e) {
      print('Error fetching event by No: $e');
      return null;
    }
  }

  // Get events by customer ID
  Future<List<Event>> getEventsByCustomer(String custId) async {
    try {
      final eventMaps = await _databaseHelper.fetchDailyEventsByCustomer(
        custId,
      );
      return eventMaps.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching events by customer: $e');
      return [];
    }
  }

  // Get events by product ID
  Future<List<Event>> getEventsByProduct(String productId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        'daily_events',
        where: 'product_id = ?',
        whereArgs: [productId],
      );
      return result.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching events by product: $e');
      return [];
    }
  }

  // Update event
  Future<bool> updateEvent(Event event) async {
    try {
      final result = await _databaseHelper.updateDailyEvent(
        event.eventNo,
        event.toMap(),
      );
      return result > 0;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventNo) async {
    try {
      final result = await _databaseHelper.deleteDailyEvent(eventNo);
      return result > 0;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // Search events by name
  Future<List<Event>> searchEventsByName(String searchTerm) async {
    try {
      final db = await _databaseHelper.database;
      final eventMaps = await db.query(
        'daily_events',
        where: 'Event_Name LIKE ? OR Expense_Name LIKE ?',
        whereArgs: ['%$searchTerm%', '%$searchTerm%'],
      );
      return eventMaps.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  // Get events by expense type
  Future<List<Event>> getEventsByExpenseType(String expenseType) async {
    try {
      final db = await _databaseHelper.database;
      final eventMaps = await db.query(
        'daily_events',
        where: 'Expense_Type = ?',
        whereArgs: [expenseType],
      );
      return eventMaps.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching events by expense type: $e');
      return [];
    }
  }

  // Get events by amount range
  Future<List<Event>> getEventsByAmountRange(
    double minAmount,
    double maxAmount,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final eventMaps = await db.query(
        'daily_events',
        where: 'Amount >= ? AND Amount <= ?',
        whereArgs: [minAmount, maxAmount],
      );
      return eventMaps.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching events by amount range: $e');
      return [];
    }
  }

  // Get events by date range
  Future<List<Event>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final eventMaps = await db.query(
        'daily_events',
        where: 'Event_Date >= ? AND Event_Date <= ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      return eventMaps.map((map) => Event.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching events by date range: $e');
      return [];
    }
  }

  // Get event count
  Future<int> getEventCount() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM events');
      return result.first['count'] as int;
    } catch (e) {
      print('Error getting event count: $e');
      return 0;
    }
  }

  // Get total amount for customer
  Future<double> getTotalAmountForCustomer(String custId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(Amount) as total FROM events WHERE Cust_ID = ?',
        [custId],
      );
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      print('Error getting total amount for customer: $e');
      return 0.0;
    }
  }

  // Get total amount for product
  Future<double> getTotalAmountForProduct(String productId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT SUM(Amount) as total FROM events WHERE Product_ID = ?',
        [productId],
      );
      return (result.first['total'] as double?) ?? 0.0;
    } catch (e) {
      print('Error getting total amount for product: $e');
      return 0.0;
    }
  }

  // Generate unique event number
  Future<String> generateEventNo() async {
    try {
      final db = await _databaseHelper.database;

      // Get the highest existing event number
      final result = await db.rawQuery('''
        SELECT Event_No FROM daily_events 
        WHERE Event_No LIKE 'EVT%' 
        ORDER BY CAST(SUBSTR(Event_No, 4) AS INTEGER) DESC 
        LIMIT 1
      ''');

      int nextNumber = 1;
      if (result.isNotEmpty) {
        final lastId = result.first['Event_No'] as String;
        final numberPart = lastId.substring(3); // Remove 'EVT' prefix
        nextNumber = (int.tryParse(numberPart) ?? 0) + 1;
      }

      // Ensure we don't have a duplicate by checking if the generated ID exists
      String candidateId;
      do {
        candidateId = 'EVT${nextNumber.toString().padLeft(4, '0')}';
        final existingEvent = await getEventByNo(candidateId);
        if (existingEvent == null) {
          break; // ID is unique
        }
        nextNumber++;
      } while (true);

      return candidateId;
    } catch (e) {
      print('Error generating event number: $e');
      return 'EVT0001'; // fallback
    }
  }

  // Check if event exists
  Future<bool> eventExists(String eventNo) async {
    try {
      return await _databaseHelper.dailyEventExists(eventNo);
    } catch (e) {
      print('Error checking if event exists: $e');
      return false;
    }
  }

  // Validate customer and product exist for event creation
  Future<bool> validateEventReferences(String custId, String productId) async {
    try {
      final customerExists = await _databaseHelper.customerExists(custId);
      final productExists = await _databaseHelper.productExists(productId);
      return customerExists && productExists;
    } catch (e) {
      print('Error validating event references: $e');
      return false;
    }
  }

  // Get events with customer and product details (joined query)
  Future<List<Map<String, dynamic>>> getEventsWithDetails() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          e.*,
          c.Customer_Name as Customer_Display_Name,
          c.Location as Customer_Location,
          p.Product_Name as Product_Display_Name,
          p.Tax_Rate as Product_Tax_Rate
        FROM events e
        LEFT JOIN customers c ON e.Cust_ID = c.Cust_ID
        LEFT JOIN products p ON e.Product_ID = p.Product_ID
        ORDER BY e.Event_Date DESC, e.Event_No DESC
      ''');
      return result;
    } catch (e) {
      print('Error getting events with details: $e');
      return [];
    }
  }
}
