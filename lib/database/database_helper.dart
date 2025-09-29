// FILE: lib/database/database_helper.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../core/constants.dart';
import '../core/connectdb.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final ConnectDB _mysqlDB = ConnectDB();

  DatabaseHelper._init();

  // Direct MySQL approach for phpMyAdmin server with enhanced fallback handling
  Future<void> initializeDatabase() async {
    try {
      debugPrint('🔄 Initializing MySQL database...');
      
      // Test connection first
      final connectionTest = await _mysqlDB.testMySQLConnection();
      if (!connectionTest) {
        debugPrint('⚠️ MySQL server not reachable - app will work in limited mode');
        debugPrint('⚠️ Server: ${ConnectDB.serverHost}:${ConnectDB.serverPort}');
        debugPrint('⚠️ Please check your internet connection and server availability');
        return; // Don't fail initialization
      }
      
      final success = await _mysqlDB.createMySQLTables();
      if (success) {
        debugPrint('✅ MySQL database initialized successfully');
      } else {
        debugPrint('⚠️ MySQL tables creation failed, but continuing...');
      }
    } catch (e) {
      debugPrint('⚠️ MySQL initialization failed: $e');
      debugPrint('⚠️ App will continue in limited mode');
      // Don't throw - allow app to continue even if MySQL is unavailable
    }
  }

  // User operations - Direct MySQL with parameterized queries
  Future<User> createUser(User user) async {
    try {
      // Use executeSelectQuery to insert and get the generated ID
      final result = await _mysqlDB.executeUpdateQuery(
        '''
        INSERT INTO users (username, email, password, first_name, last_name, 
                          shop_name, shop_address, shop_phone, shop_email, 
                          currency, payment_qr, profile_image, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''',
        [
          user.username,
          user.email,
          user.password,
          user.firstName,
          user.lastName,
          user.shopName,
          user.shopAddress ?? '',
          user.shopPhone ?? '',
          user.shopEmail ?? '',
          user.currency,
          user.paymentQr ?? '',
          user.profileImage ?? '',
          user.createdAt?.toIso8601String(),
          user.updatedAt?.toIso8601String(),
        ],
      );
      
      if (result) {
        // Get the created user by email to retrieve the generated ID
        final createdUser = await getUserByEmail(user.email);
        if (createdUser != null) {
          debugPrint('✅ User created successfully with ID: ${createdUser.id}');
          return createdUser;
        } else {
          throw Exception('Failed to retrieve created user from MySQL');
        }
      } else {
        throw Exception('Failed to insert user into MySQL');
      }
    } catch (e) {
      debugPrint('❌ User creation failed: $e');
      throw Exception('User creation failed: $e');
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        'SELECT * FROM users WHERE email = ? LIMIT 1',
        [email]
      );
      
      if (results.isNotEmpty) {
        return User.fromMap(results.first);
      }
      return null;
    } catch (e) {
      debugPrint('Get user by email failed: $e');
      debugPrint('⚠️ MySQL connection issue - check network connectivity');
      return null;
    }
  }

  Future<User?> getUserByUsername(String username) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        'SELECT * FROM users WHERE username = ? LIMIT 1',
        [username]
      );
      
      if (results.isNotEmpty) {
        return User.fromMap(results.first);
      }
      return null;
    } catch (e) {
      debugPrint('Get user by username failed: $e');
      debugPrint('⚠️ MySQL connection issue - check network connectivity');
      return null;
    }
  }

  Future<User?> getUser(int id) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        'SELECT * FROM users WHERE id = ? LIMIT 1',
        [id]
      );
      
      if (results.isNotEmpty) {
        return User.fromMap(results.first);
      }
      return null;
    } catch (e) {
      debugPrint('Get user failed: $e');
      return null;
    }
  }

  Future<int> updateUser(User user) async {
    try {
      final success = await _mysqlDB.executeUpdateQuery(
        '''UPDATE users SET 
           username = ?, email = ?, first_name = ?, last_name = ?,
           shop_name = ?, shop_address = ?, shop_phone = ?, shop_email = ?,
           currency = ?, payment_qr = ?, profile_image = ?, updated_at = NOW()
           WHERE id = ?''',
        [
          user.username, user.email, user.firstName, user.lastName,
          user.shopName, user.shopAddress, user.shopPhone, user.shopEmail,
          user.currency, user.paymentQr, user.profileImage, user.id
        ]
      );
      
      return success ? 1 : 0;
    } catch (e) {
      debugPrint('Update user failed: $e');
      return 0;
    }
  }

  Future<int> updateUserPassword(int userId, String hashedPassword) async {
    try {
      final success = await _mysqlDB.executeUpdateQuery(
        'UPDATE users SET password = ?, updated_at = NOW() WHERE id = ?',
        [hashedPassword, userId]
      );
      
      return success ? 1 : 0;
    } catch (e) {
      debugPrint('Update user password failed: $e');
      return 0;
    }
  }

  // Product operations - Direct MySQL with parameterized queries
  Future<Product> createProduct(Product product) async {
    try {
      final success = await _mysqlDB.syncProductToMySQL(product);
      if (success) {
        return product;
      } else {
        throw Exception('Failed to create product in MySQL');
      }
    } catch (e) {
      throw Exception('Product creation failed: $e');
    }
  }

  Future<List<Product>> getProducts(int userId) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        'SELECT * FROM products WHERE user_id = ? ORDER BY name ASC',
        [userId]
      );
      
      return results.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Get products failed: $e');
      return [];
    }
  }

  Future<Product?> getProductByCode(String code, int userId) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        'SELECT * FROM products WHERE code = ? AND user_id = ? LIMIT 1',
        [code, userId]
      );
      
      if (results.isNotEmpty) {
        return Product.fromMap(results.first);
      }
      return null;
    } catch (e) {
      debugPrint('Get product by code failed: $e');
      return null;
    }
  }

  Future<int> updateProduct(Product product) async {
    try {
      final success = await _mysqlDB.executeUpdateQuery(
        '''UPDATE products SET 
           name = ?, price = ?, quantity = ?, low_stock = ?, code = ?,
           category = ?, unit = ?, image = ?, updated_at = NOW()
           WHERE id = ? AND user_id = ?''',
        [
          product.name, product.price, product.quantity, product.lowStock, product.code,
          product.category, product.unit, product.image, product.id, product.userId
        ]
      );
      
      return success ? 1 : 0;
    } catch (e) {
      debugPrint('Update product failed: $e');
      return 0;
    }
  }

  Future<int> deleteProduct(int id, int userId) async {
    try {
      // First, delete all sale items associated with this product
      await _mysqlDB.executeUpdateQuery(
        'DELETE FROM sale_items WHERE product_id = ?',
        [id]
      );
      
      // Then, delete all inventory records associated with this product
      await _mysqlDB.executeUpdateQuery(
        'DELETE FROM inventories WHERE product_id = ?',
        [id]
      );
      
      // Finally, delete the product itself
      final success = await _mysqlDB.executeUpdateQuery(
        'DELETE FROM products WHERE id = ? AND user_id = ?',
        [id, userId]
      );
      
      return success ? 1 : 0;
    } catch (e) {
      debugPrint('Delete product failed: $e');
      return 0;
    }
  }

  // Sale operations - Direct MySQL with parameterized queries
  Future<Sale> createSale(Sale sale, List<SaleItem> items) async {
    try {
      final success = await _mysqlDB.syncSaleToMySQL(sale, items);
      if (success) {
        return sale;
      } else {
        throw Exception('Failed to create sale in MySQL');
      }
    } catch (e) {
      throw Exception('Sale creation failed: $e');
    }
  }

  Future<List<Sale>> getSales(int userId) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        'SELECT * FROM sales WHERE user_id = ? ORDER BY sale_date DESC',
        [userId]
      );
      
      return results.map((map) => Sale.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Get sales failed: $e');
      return [];
    }
  }

  Future<List<Sale>> getSalesToday(int userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
      
      final results = await _mysqlDB.executeSelectQuery(
        '''SELECT * FROM sales 
           WHERE user_id = ? AND sale_date >= ? AND sale_date <= ?
           ORDER BY sale_date DESC''',
        [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()]
      );
      
      return results.map((map) => Sale.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Get today sales failed: $e');
      return [];
    }
  }

  Future<double> getTotalSalesToday(int userId) async {
    try {
      final sales = await getSalesToday(userId);
      return sales.fold<double>(0.0, (double sum, Sale sale) => sum + sale.totalAmount);
    } catch (e) {
      debugPrint('Get total sales today failed: $e');
      return 0.0;
    }
  }

  Future<List<Product>> getLowStockProducts(int userId) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        'SELECT * FROM products WHERE user_id = ? AND quantity <= low_stock ORDER BY quantity ASC',
        [userId]
      );
      
      return results.map((map) => Product.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Get low stock products failed: $e');
      return [];
    }
  }

  // Advanced Analytics Methods

  /// Get sales data grouped by hour for peak hour analysis
  Future<Map<String, dynamic>> getSalesByHour(int userId, DateTime startDate, DateTime endDate) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        '''SELECT HOUR(sale_date) as hour, COUNT(*) as transaction_count, 
           SUM(total_amount) as total_revenue
           FROM sales 
           WHERE user_id = ? AND sale_date >= ? AND sale_date <= ?
           GROUP BY HOUR(sale_date)
           ORDER BY hour''',
        [userId, startDate.toIso8601String(), endDate.toIso8601String()]
      );
      
      return {
        'hourlyData': results,
      };
    } catch (e) {
      debugPrint('Get sales by hour failed: $e');
      return {'hourlyData': []};
    }
  }

  /// Get sales data grouped by day for trend analysis
  Future<Map<String, dynamic>> getSalesByDay(int userId, DateTime startDate, DateTime endDate) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        '''SELECT DATE(sale_date) as sale_day, COUNT(*) as transaction_count, 
           SUM(total_amount) as total_revenue
           FROM sales 
           WHERE user_id = ? AND sale_date >= ? AND sale_date <= ?
           GROUP BY DATE(sale_date)
           ORDER BY sale_day''',
        [userId, startDate.toIso8601String(), endDate.toIso8601String()]
      );
      
      return {
        'dailyData': results,
      };
    } catch (e) {
      debugPrint('Get sales by day failed: $e');
      return {'dailyData': []};
    }
  }

  /// Get top selling products by revenue
  Future<List<Map<String, dynamic>>> getTopSellingProducts(int userId, DateTime startDate, DateTime endDate, {int limit = 10}) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        '''SELECT p.name, p.code, p.image, 
           SUM(si.quantity) as total_quantity, 
           SUM(si.total_price) as total_revenue,
           COUNT(si.id) as sale_count
           FROM sale_items si
           JOIN sales s ON si.sale_id = s.id
           JOIN products p ON si.product_id = p.id
           WHERE s.user_id = ? AND s.sale_date >= ? AND s.sale_date <= ?
           GROUP BY si.product_id, p.name, p.code, p.image
           ORDER BY total_revenue DESC
           LIMIT ?''',
        [userId, startDate.toIso8601String(), endDate.toIso8601String(), limit]
      );
      
      return results;
    } catch (e) {
      debugPrint('Get top selling products failed: $e');
      return [];
    }
  }

  /// Get customer purchase history
  Future<List<Map<String, dynamic>>> getCustomerPurchaseHistory(int userId, {int limit = 50}) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        '''SELECT customer_name, customer_phone, 
           COUNT(*) as purchase_count, 
           SUM(total_amount) as total_spent,
           MAX(sale_date) as last_purchase_date
           FROM sales 
           WHERE user_id = ? AND customer_name IS NOT NULL
           GROUP BY customer_name, customer_phone
           ORDER BY total_spent DESC
           LIMIT ?''',
        [userId, limit]
      );
      
      return results;
    } catch (e) {
      debugPrint('Get customer purchase history failed: $e');
      return [];
    }
  }

  /// Get inventory movement data for stock analysis
  Future<Map<String, dynamic>> getInventoryMovement(int userId, DateTime startDate, DateTime endDate) async {
    try {
      final results = await _mysqlDB.executeSelectQuery(
        '''SELECT p.name, p.code, 
           SUM(CASE WHEN i.change_type = 'SALE' THEN i.stock_before - i.stock_after ELSE 0 END) as sold_quantity,
           SUM(CASE WHEN i.change_type = 'STOCK_IN' THEN i.stock_after - i.stock_before ELSE 0 END) as received_quantity,
           MAX(i.created_at) as last_updated
           FROM inventories i
           JOIN products p ON i.product_id = p.id
           WHERE i.user_id = ? AND i.created_at >= ? AND i.created_at <= ?
           GROUP BY p.id, p.name, p.code
           ORDER BY sold_quantity DESC''',
        [userId, startDate.toIso8601String(), endDate.toIso8601String()]
      );
      
      return {
        'inventoryData': results,
      };
    } catch (e) {
      debugPrint('Get inventory movement failed: $e');
      return {'inventoryData': []};
    }
  }

  /// Get reorder suggestions based on sales velocity
  Future<List<Map<String, dynamic>>> getReorderSuggestions(int userId) async {
    try {
      // Get products with low stock that have high sales velocity
      final results = await _mysqlDB.executeSelectQuery(
        '''SELECT p.name, p.code, p.quantity, p.low_stock, p.unit,
           COALESCE(sales_data.avg_daily_sales, 0) as avg_daily_sales,
           CASE 
             WHEN sales_data.avg_daily_sales > 0 THEN p.quantity / sales_data.avg_daily_sales
             ELSE 999 
           END as days_until_out_of_stock
           FROM products p
           LEFT JOIN (
             SELECT si.product_id, 
                    SUM(si.quantity) / 30.0 as avg_daily_sales
             FROM sale_items si
             JOIN sales s ON si.sale_id = s.id
             WHERE s.user_id = ? AND s.sale_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
             GROUP BY si.product_id
           ) sales_data ON p.id = sales_data.product_id
           WHERE p.user_id = ? AND p.quantity <= p.low_stock * 1.5
           ORDER BY days_until_out_of_stock ASC''',
        [userId, userId]
      );
      
      return results;
    } catch (e) {
      debugPrint('Get reorder suggestions failed: $e');
      return [];
    }
  }

  Future<void> close() async {
    try {
      await _mysqlDB.close();
      debugPrint('MySQL database connection closed');
    } catch (e) {
      debugPrint('Error closing MySQL database connection: $e');
    }
  }
  
  // ==================== MYSQL DATABASE TESTING ====================
  
  /// Test MySQL database operations
  Future<bool> testDatabaseOperations() async {
    try {
      debugPrint('🔄 Testing MySQL database operations...');
      
      // Test connection first
      bool canConnect = await _mysqlDB.testMySQLConnection();
      if (!canConnect) {
        debugPrint('❌ Cannot connect to MySQL server');
        return false;
      }

      // Test table creation
      bool tablesCreated = await _mysqlDB.createMySQLTables();
      if (!tablesCreated) {
        debugPrint('❌ Failed to create MySQL tables');
        return false;
      }
      
      debugPrint('✅ MySQL database operations test completed successfully');
      return true;
      
    } catch (e) {
      debugPrint('❌ MySQL database operations test error: $e');
      return false;
    }
  }
}