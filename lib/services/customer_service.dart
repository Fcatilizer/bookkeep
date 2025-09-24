import '../helpers/database_helper.dart';
import '../models/customer.dart';

class CustomerService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Create a new customer
  Future<bool> createCustomer(Customer customer) async {
    try {
      print(
        'Attempting to create customer: ${customer.custId} - ${customer.customerName}',
      );
      final result = await _databaseHelper.insertCustomer(customer.toMap());
      print('Customer created successfully with result: $result');
      return result > 0; // Return true only if a row was actually inserted
    } catch (e) {
      print('Error creating customer: $e');
      print('Customer data: ${customer.toMap()}');
      return false;
    }
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    try {
      final customerMaps = await _databaseHelper.fetchCustomers();
      return customerMaps.map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  // Get customer by ID
  Future<Customer?> getCustomerById(String custId) async {
    try {
      final db = await _databaseHelper.database;
      final customerMaps = await db.query(
        'customers',
        where: 'Cust_ID = ?',
        whereArgs: [custId],
      );

      if (customerMaps.isNotEmpty) {
        return Customer.fromMap(customerMaps.first);
      }
      return null;
    } catch (e) {
      print('Error fetching customer by ID: $e');
      return null;
    }
  }

  // Update customer
  Future<bool> updateCustomer(Customer customer) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'customers',
        customer.toMap(),
        where: 'Cust_ID = ?',
        whereArgs: [customer.custId],
      );
      return result > 0;
    } catch (e) {
      print('Error updating customer: $e');
      return false;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(String custId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'customers',
        where: 'Cust_ID = ?',
        whereArgs: [custId],
      );
      return result > 0;
    } catch (e) {
      print('Error deleting customer: $e');
      return false;
    }
  }

  // Search customers by name
  Future<List<Customer>> searchCustomersByName(String searchTerm) async {
    try {
      final db = await _databaseHelper.database;
      final customerMaps = await db.query(
        'customers',
        where: 'Customer_Name LIKE ?',
        whereArgs: ['%$searchTerm%'],
      );
      return customerMaps.map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  // Get customers by location
  Future<List<Customer>> getCustomersByLocation(String location) async {
    try {
      final db = await _databaseHelper.database;
      final customerMaps = await db.query(
        'customers',
        where: 'Location = ?',
        whereArgs: [location],
      );
      return customerMaps.map((map) => Customer.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching customers by location: $e');
      return [];
    }
  }

  // Get customer count
  Future<int> getCustomerCount() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM customers',
      );
      return result.first['count'] as int;
    } catch (e) {
      print('Error getting customer count: $e');
      return 0;
    }
  }

  // Generate unique customer ID
  Future<String> generateCustomerId() async {
    try {
      final db = await _databaseHelper.database;

      // Get the highest existing customer ID number
      final result = await db.rawQuery('''
        SELECT Cust_ID FROM customers 
        WHERE Cust_ID LIKE 'CUST%' 
        ORDER BY CAST(SUBSTR(Cust_ID, 5) AS INTEGER) DESC 
        LIMIT 1
      ''');

      int nextNumber = 1;
      if (result.isNotEmpty) {
        final lastId = result.first['Cust_ID'] as String;
        final numberPart = lastId.substring(4); // Remove 'CUST' prefix
        nextNumber = (int.tryParse(numberPart) ?? 0) + 1;
      }

      // Ensure we don't have a duplicate by checking if the generated ID exists
      String candidateId;
      do {
        candidateId = 'CUST${nextNumber.toString().padLeft(4, '0')}';
        final existingCustomer = await getCustomerById(candidateId);
        if (existingCustomer == null) {
          break; // ID is unique
        }
        nextNumber++;
      } while (true);

      return candidateId;
    } catch (e) {
      print('Error generating customer ID: $e');
      return 'CUST0001'; // fallback
    }
  }
}
