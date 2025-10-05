// FILE: lib/core/connectdb.dart
// Direct MySQL connection for Jame project - Single file solution
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mysql1/mysql1.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';

class ConnectDB {
  static final ConnectDB _instance = ConnectDB._internal();
  factory ConnectDB() => _instance;
  ConnectDB._internal();

  // ==================== MySQL Server Configuration from .env ====================
  static String get serverHost {
    final host = dotenv.env['DB_HOST'];
    if (host == null || host.isEmpty) {
      throw Exception('DB_HOST not found in .env file');
    }
    return host;
  }
  
  static int get serverPort {
    return 3306;
  }
  
  static String get serverUser {
    final user = dotenv.env['DB_USERNAME'];
    if (user == null || user.isEmpty) {
      throw Exception('DB_USERNAME not found in .env file');
    }
    return user;
  }
  
  static String get serverPassword {
    final password = dotenv.env['DB_PASSWORD'];
    if (password == null || password.isEmpty) {
      throw Exception('DB_PASSWORD not found in .env file');
    }
    return password;
  }
  
  static String get serverDatabase {
    final database = dotenv.env['DB_NAME'];
    if (database == null || database.isEmpty) {
      throw Exception('DB_NAME not found in .env file');
    }
    return database;
  }
  
  static Duration get connectionTimeout => Duration(seconds: 10);
  
  MySqlConnection? _connection;
  DateTime? _lastConnectionTime;
  static const Duration _connectionMaxAge = Duration(minutes: 5);

  // ==================== MYSQL CONNECTION MANAGEMENT ====================
  
  /// Get MySQL connection settings - matches PHP PDO configuration
  ConnectionSettings get _connectionSettings {
    return ConnectionSettings(
      host: serverHost,
      port: serverPort,
      user: serverUser,
      password: serverPassword,
      db: serverDatabase,
      timeout: connectionTimeout,
    );
  }
  
  /// Get or create MySQL connection with proper lifecycle management
  Future<MySqlConnection> _getConnection() async {
    try {
      // Check if we need a new connection
      if (_connection == null || _isConnectionStale()) {
        await _closeExistingConnection();
        
        // Create new connection with timeout
        _connection = await MySqlConnection.connect(_connectionSettings)
            .timeout(Duration(seconds: 10));
        _lastConnectionTime = DateTime.now();
      }
      return _connection!;
    } catch (e) {
      await _closeExistingConnection(); // Clean up on failure
      rethrow;
    }
  }
  
  /// Check if current connection is stale and should be recreated
  bool _isConnectionStale() {
    if (_lastConnectionTime == null) return true;
    return DateTime.now().difference(_lastConnectionTime!) > _connectionMaxAge;
  }
  
  /// Close existing connection properly
  Future<void> _closeExistingConnection() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
        _lastConnectionTime = null;
      }
    } catch (e) {
      _connection = null;
      _lastConnectionTime = null;
    }
  }
  
  /// Test direct connection to MySQL server
  Future<bool> testMySQLConnection({int maxRetries = 2}) async {
    return await _performConnectionTest(maxRetries);
  }
  
  /// Internal connection test that can be run in background
  Future<bool> _performConnectionTest(int maxRetries) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Create connection settings matching PHP PDO configuration
        final connectionSettings = ConnectionSettings(
          host: serverHost,
          port: serverPort,
          user: serverUser,
          password: serverPassword,
          db: serverDatabase,
          timeout: Duration(seconds: 10),
        );
        
        // Test connection with timeout and immediate cleanup
        final connection = await Future.any([
          MySqlConnection.connect(connectionSettings),
          Future.delayed(Duration(seconds: 10), () => throw TimeoutException('Connection timeout', Duration(seconds: 10)))
        ]);
        
        await connection.close();
        
        return true;
        
      } catch (e) {
        if (attempt == maxRetries) {
          // Final failure
        } else {
          // Brief delay between retries
          await Future.delayed(Duration(milliseconds: 300));
        }
      }
    }
    return false;
  }

  /// Get MySQL server status information
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final connection = await MySqlConnection.connect(_connectionSettings)
          .timeout(Duration(seconds: 10));
      
      // Get server version
      final versionResult = await connection.query('SELECT VERSION() as version');
      final version = versionResult.isNotEmpty ? versionResult.first['version'] : 'Unknown';
      
      // Get connection info
      final connectionInfo = {
        'host': serverHost,
        'port': serverPort,
        'user': serverUser,
        'database': serverDatabase,
      };
      
      await connection.close();
      
      return {
        'connected': true,
        'version': version,
        'connection_info': connectionInfo,
      };
    } catch (e) {
      return {
        'connected': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== MYSQL DATABASE OPERATIONS ====================
  
  /// Execute MySQL SELECT query with parameters and return results
  Future<List<Map<String, dynamic>>> executeSelectQuery(String query, [List<dynamic>? parameters]) async {
    MySqlConnection? connection;
    try {
      // Get fresh connection for each query to avoid socket issues
      connection = await MySqlConnection.connect(_connectionSettings)
          .timeout(Duration(seconds: 10));
      
      final results = await connection.query(query, parameters);
      
      // Convert results to List<Map<String, dynamic>>
      List<Map<String, dynamic>> rows = [];
      for (var row in results) {
        Map<String, dynamic> rowMap = {};
        for (int i = 0; i < row.length; i++) {
          final fieldName = results.fields[i].name ?? 'field_$i';
          rowMap[fieldName] = row[i];
        }
        rows.add(rowMap);
      }
      
      return rows;
      
    } catch (e) {
      throw Exception('SELECT query failed: $e');
    } finally {
      // Always close the connection after use
      try {
        await connection?.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }
  
  /// Execute MySQL UPDATE/INSERT/DELETE query with parameters
  Future<bool> executeUpdateQuery(String query, [List<dynamic>? parameters]) async {
    MySqlConnection? connection;
    try {
      // Get fresh connection for each query to avoid socket issues
      connection = await MySqlConnection.connect(_connectionSettings)
          .timeout(Duration(seconds: 10));
      
      final result = await connection.query(query, parameters);
      
      return result.affectedRows != null && result.affectedRows! > 0;
      
    } catch (e) {
      return false;
    } finally {
      // Always close the connection after use
      try {
        await connection?.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  /// Sync individual user to MySQL with parameterized queries
  Future<bool> syncUserToMySQL(User user) async {
    MySqlConnection? connection;
    try {
      // Get fresh connection for sync operation
      connection = await MySqlConnection.connect(_connectionSettings)
          .timeout(Duration(seconds: 10));
      
      // Use parameterized query to prevent SQL injection
      // Remove id from INSERT to let MySQL auto-increment assign it
      final result = await connection.query(
        '''
        INSERT INTO users (username, email, password, first_name, last_name, 
                          shop_name, shop_address, shop_phone, shop_email, 
                          currency, payment_qr, profile_image, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        username=VALUES(username), email=VALUES(email), 
        first_name=VALUES(first_name), last_name=VALUES(last_name),
        shop_name=VALUES(shop_name), updated_at=VALUES(updated_at)
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
          user.createdAt != null ? user.createdAt!.toUtc().toIso8601String().split('.')[0].replaceAll('T', ' ').replaceAll('Z', '') : null,
          user.updatedAt != null ? user.updatedAt!.toUtc().toIso8601String().split('.')[0].replaceAll('T', ' ').replaceAll('Z', '') : null,
        ],
      );
      
      return result.affectedRows != null && result.affectedRows! > 0;
      
    } catch (e) {
      return false;
    } finally {
      try {
        await connection?.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  /// Sync individual product to MySQL with parameterized queries
  Future<bool> syncProductToMySQL(Product product) async {
    MySqlConnection? connection;
    try {
      // Get fresh connection for sync operation
      connection = await MySqlConnection.connect(_connectionSettings)
          .timeout(Duration(seconds: 10));
      
      // Use parameterized query to prevent SQL injection
      final result = await connection.query(
        '''
        INSERT INTO products (id, user_id, name, price, quantity, low_stock, code,
                             category, unit, image, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        name=VALUES(name), price=VALUES(price), quantity=VALUES(quantity),
        low_stock=VALUES(low_stock), category=VALUES(category),
        unit=VALUES(unit), updated_at=VALUES(updated_at)
        ''',
        [
          product.id,
          product.userId,
          product.name,
          product.price,
          product.quantity,
          product.lowStock,
          product.code,
          product.category ?? '',
          product.unit,
          product.image ?? '',
          product.createdAt != null ? product.createdAt!.toUtc().toIso8601String().split('.')[0].replaceAll('T', ' ').replaceAll('Z', '') : null,
          product.updatedAt != null ? product.updatedAt!.toUtc().toIso8601String().split('.')[0].replaceAll('T', ' ').replaceAll('Z', '') : null,
        ],
      );
      
      return result.affectedRows != null && result.affectedRows! > 0;
      
    } catch (e) {
      return false;
    } finally {
      try {
        await connection?.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  /// Sync individual sale to MySQL with parameterized queries
  Future<bool> syncSaleToMySQL(Sale sale, List<SaleItem> items) async {
    MySqlConnection? connection;
    try {
      // Get fresh connection for sync operation
      connection = await MySqlConnection.connect(_connectionSettings)
          .timeout(Duration(seconds: 10));
      
      // First sync the sale with parameterized query
      final saleResult = await connection.query(
        '''
        INSERT INTO sales (user_id, sale_date, total_amount, payment_status,
                          receipt_number, payment_method, description, 
                          customer_name, customer_phone)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        total_amount=VALUES(total_amount), payment_status=VALUES(payment_status),
        payment_method=VALUES(payment_method)
        ''',
        [
          sale.userId,
          sale.saleDate.toUtc() != null ? sale.saleDate.toUtc()!.toIso8601String().split('.')[0].replaceAll('T', ' ').replaceAll('Z', '') : null,
          sale.totalAmount,
          sale.paymentStatus,
          sale.receiptNumber,
          sale.paymentMethod,
          sale.description ?? '',
          sale.customerName ?? '',
          sale.customerPhone ?? '',
        ],
      );
      
      // Get the sale ID (either inserted or existing)
      int saleId;
      if (saleResult.insertId != null && saleResult.insertId! > 0) {
        saleId = saleResult.insertId!;
      } else {
        // If it was an update, find the existing sale ID
        final existingSale = await connection.query(
          'SELECT id FROM sales WHERE receipt_number = ? AND user_id = ? LIMIT 1',
          [sale.receiptNumber, sale.userId]
        );
        if (existingSale.isNotEmpty) {
          saleId = existingSale.first['id'];
        } else {
          throw Exception('Could not determine sale ID after insertion');
        }
      }
      
      if (saleResult.affectedRows != null && saleResult.affectedRows! > 0) {
        // Then sync all sale items with the correct sale_id
        for (var item in items) {
          await connection.query(
            '''
            INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, total_price)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            quantity=VALUES(quantity), unit_price=VALUES(unit_price), 
            total_price=VALUES(total_price)
            ''',
            [
              saleId, // Use the actual sale ID from database
              item.productId,
              item.quantity,
              item.unitPrice,
              item.totalPrice,
            ],
          );
        }
      }
      
      return saleResult.affectedRows != null && saleResult.affectedRows! > 0;
      
    } catch (e) {
      return false;
    } finally {
      try {
        await connection?.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Create MySQL database tables that match your SQLite schema
  Future<bool> createMySQLTables() async {
    try {
      // SQL to create all tables with the same structure as your SQLite
      List<String> createTableQueries = [
        // Users table
        '''
          CREATE TABLE IF NOT EXISTS users (
            id INT PRIMARY KEY AUTO_INCREMENT,
            username VARCHAR(255) UNIQUE NOT NULL,
            email VARCHAR(255) UNIQUE NOT NULL,
            password VARCHAR(255) NOT NULL,
            first_name VARCHAR(255) NOT NULL,
            last_name VARCHAR(255) NOT NULL,
            shop_name VARCHAR(255) NOT NULL,
            shop_address TEXT,
            shop_phone VARCHAR(50),
            shop_email VARCHAR(255),
            currency VARCHAR(10) DEFAULT 'THB',
            payment_qr TEXT,
            profile_image TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
          ) ENGINE=InnoDB;
        ''',
        
        // Products table
        '''
          CREATE TABLE IF NOT EXISTS products (
            id INT PRIMARY KEY AUTO_INCREMENT,
            user_id INT NOT NULL,
            name VARCHAR(255) NOT NULL,
            price DECIMAL(10,2) NOT NULL,
            quantity INT NOT NULL DEFAULT 0,
            low_stock INT DEFAULT 5,
            code VARCHAR(255) NOT NULL,
            category VARCHAR(255),
            unit VARCHAR(50) DEFAULT 'pcs',
            image TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE KEY unique_code_per_user (user_id, code),
            INDEX idx_products_user_id (user_id)
          ) ENGINE=InnoDB;
        ''',
        
        // Sales table
        '''
          CREATE TABLE IF NOT EXISTS sales (
            id INT PRIMARY KEY AUTO_INCREMENT,
            user_id INT NOT NULL,
            sale_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            total_amount DECIMAL(10,2) NOT NULL,
            payment_status VARCHAR(50) DEFAULT 'Completed',
            receipt_number VARCHAR(255) NOT NULL,
            payment_method VARCHAR(50) DEFAULT 'QR',
            description TEXT,
            customer_name VARCHAR(255),
            customer_phone VARCHAR(50),
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE KEY unique_receipt_per_user (user_id, receipt_number),
            INDEX idx_sales_user_id (user_id),
            INDEX idx_sales_date_user (user_id, sale_date)
          ) ENGINE=InnoDB;
        ''',
        
        // Sale items table
        '''
          CREATE TABLE IF NOT EXISTS sale_items (
            id INT PRIMARY KEY AUTO_INCREMENT,
            sale_id INT NOT NULL,
            product_id INT NOT NULL,
            quantity INT NOT NULL,
            unit_price DECIMAL(10,2) NOT NULL,
            total_price DECIMAL(10,2) NOT NULL,
            FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id),
            INDEX idx_sale_items_sale_id (sale_id),
            INDEX idx_sale_items_product_id (product_id)
          ) ENGINE=InnoDB;
        ''',
        
        // Cart items table
        '''
          CREATE TABLE IF NOT EXISTS cart_items (
            id INT PRIMARY KEY AUTO_INCREMENT,
            user_id INT NOT NULL,
            product_id INT NOT NULL,
            quantity INT NOT NULL DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
            UNIQUE KEY unique_cart_item_per_user (user_id, product_id),
            INDEX idx_cart_items_user_id (user_id),
            INDEX idx_cart_items_product_id (product_id)
          ) ENGINE=InnoDB;
        ''',
        
        // Inventories table
        '''
          CREATE TABLE IF NOT EXISTS inventories (
            id INT PRIMARY KEY AUTO_INCREMENT,
            user_id INT NOT NULL,
            product_id INT NOT NULL,
            change_type VARCHAR(50) NOT NULL,
            stock_before INT NOT NULL,
            stock_after INT NOT NULL,
            reference_id INT,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (product_id) REFERENCES products(id),
            INDEX idx_inventory_user_id (user_id),
            INDEX idx_inventory_product_user (user_id, product_id)
          ) ENGINE=InnoDB;
        '''
      ];
      
      // Execute each CREATE TABLE query
      for (String query in createTableQueries) {
        final result = await _executeMySQLCommand(query);
        if (result['success'] != true) {
          return false;
        }
      }
      
      return true;
      
    } catch (e) {
      return false;
    }
  }

  /// Execute MySQL command with proper SQL execution
  Future<Map<String, dynamic>> _executeMySQLCommand(String sqlCommand) async {
    MySqlConnection? connection;
    try {
      // Get fresh connection for command execution
      connection = await MySqlConnection.connect(_connectionSettings)
          .timeout(Duration(seconds: 10));
      
      // Execute the SQL command
      final result = await connection.query(sqlCommand);
      
      return {
        'success': true, 
        'message': 'Command executed successfully',
        'affected_rows': result.affectedRows,
        'insert_id': result.insertId,
      };
      
    } catch (e) {
      return {'success': false, 'message': 'Command failed: $e'};
    } finally {
      try {
        await connection?.close();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  /// Check if MySQL server is reachable
  Future<bool> isServerAvailable() async {
    return await testMySQLConnection();
  }

  /// Close any open connections
  Future<void> close() async {
    try {
      await _closeExistingConnection();
    } catch (e) {
      // Ignore cleanup errors
    }
  }
}

// ==================== SYNC RESULT MODEL ====================

class SyncResult {
  bool success = false;
  String message = '';
  DateTime? lastSyncTime;
  int productsCount = 0;
  int salesCount = 0;

  SyncResult({
    this.success = false,
    this.message = '',
    this.lastSyncTime,
    this.productsCount = 0,
    this.salesCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'last_sync_time': lastSyncTime?.toIso8601String(),
      'products_count': productsCount,
      'sales_count': salesCount,
    };
  }

  factory SyncResult.fromMap(Map<String, dynamic> map) {
    return SyncResult(
      success: map['success'] ?? false,
      message: map['message'] ?? '',
      lastSyncTime: map['last_sync_time'] != null 
          ? DateTime.parse(map['last_sync_time']) 
          : null,
      productsCount: map['products_count'] ?? 0,
      salesCount: map['sales_count'] ?? 0,
    );
  }
}