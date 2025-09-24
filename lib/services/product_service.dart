import '../helpers/database_helper.dart';
import '../models/product.dart';

class ProductService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Create a new product
  Future<bool> createProduct(Product product) async {
    try {
      print(
        'Attempting to create product: ${product.productId} - ${product.productName}',
      );
      final result = await _databaseHelper.insertProduct(product.toMap());
      print('Product created successfully with result: $result');
      return result > 0; // Return true only if a row was actually inserted
    } catch (e) {
      print('Error creating product: $e');
      print('Product data: ${product.toMap()}');
      return false;
    }
  }

  // Get all products
  Future<List<Product>> getAllProducts() async {
    try {
      final productMaps = await _databaseHelper.fetchProducts();
      return productMaps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final db = await _databaseHelper.database;
      final productMaps = await db.query(
        'products',
        where: 'Product_ID = ?',
        whereArgs: [productId],
      );

      if (productMaps.isNotEmpty) {
        return Product.fromMap(productMaps.first);
      }
      return null;
    } catch (e) {
      print('Error fetching product by ID: $e');
      return null;
    }
  }

  // Update product
  Future<bool> updateProduct(Product product) async {
    try {
      final result = await _databaseHelper.updateProduct(
        product.productId,
        product.toMap(),
      );
      return result > 0;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      final result = await _databaseHelper.deleteProduct(productId);
      return result > 0;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }

  // Search products by name
  Future<List<Product>> searchProductsByName(String searchTerm) async {
    try {
      final db = await _databaseHelper.database;
      final productMaps = await db.query(
        'products',
        where: 'Product_Name LIKE ?',
        whereArgs: ['%$searchTerm%'],
      );
      return productMaps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Get products by tax rate range
  Future<List<Product>> getProductsByTaxRateRange(
    double minRate,
    double maxRate,
  ) async {
    try {
      final db = await _databaseHelper.database;
      final productMaps = await db.query(
        'products',
        where: 'Tax_Rate >= ? AND Tax_Rate <= ?',
        whereArgs: [minRate, maxRate],
      );
      return productMaps.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching products by tax rate: $e');
      return [];
    }
  }

  // Get product count
  Future<int> getProductCount() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM products',
      );
      return result.first['count'] as int;
    } catch (e) {
      print('Error getting product count: $e');
      return 0;
    }
  }

  // Generate unique product ID
  Future<String> generateProductId() async {
    try {
      final db = await _databaseHelper.database;

      // Get the highest existing product ID number
      final result = await db.rawQuery('''
        SELECT Product_ID FROM products 
        WHERE Product_ID LIKE 'PROD%' 
        ORDER BY CAST(SUBSTR(Product_ID, 5) AS INTEGER) DESC 
        LIMIT 1
      ''');

      int nextNumber = 1;
      if (result.isNotEmpty) {
        final lastId = result.first['Product_ID'] as String;
        final numberPart = lastId.substring(4); // Remove 'PROD' prefix
        nextNumber = (int.tryParse(numberPart) ?? 0) + 1;
      }

      // Ensure we don't have a duplicate by checking if the generated ID exists
      String candidateId;
      do {
        candidateId = 'PROD${nextNumber.toString().padLeft(4, '0')}';
        final existingProduct = await getProductById(candidateId);
        if (existingProduct == null) {
          break; // ID is unique
        }
        nextNumber++;
      } while (true);

      return candidateId;
    } catch (e) {
      print('Error generating product ID: $e');
      return 'PROD0001'; // fallback
    }
  }

  // Check if product exists
  Future<bool> productExists(String productId) async {
    try {
      return await _databaseHelper.productExists(productId);
    } catch (e) {
      print('Error checking if product exists: $e');
      return false;
    }
  }
}
