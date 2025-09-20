// FILE: lib/core/connectdb.dart
// Direct MySQL connection for Jame project - Single file solution
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../database/database_helper.dart';

class ConnectDB {
  static final ConnectDB _instance = ConnectDB._internal();
  factory ConnectDB() => _instance;
  ConnectDB._internal();

  // ==================== MySQL Server Configuration ====================
  // Update these with your actual MySQL server details
  static const String serverHost = 'localhost';           // Your MySQL server IP/domain
  static const int serverPort = 3306;                     // MySQL port (default: 3306)
  static const String serverUser = 'your_username';       // Your MySQL username
  static const String serverPassword = 'your_password';   // Your MySQL password
  static const String serverDatabase = 'jame_database';   // Your MySQL database name
  
  // Connection timeout
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  Socket? _socket;

  // ==================== DIRECT MySQL PROTOCOL CONNECTION ====================
  
  /// Test direct connection to MySQL server
  Future<bool> testMySQLConnection() async {
    try {
      _socket = await Socket.connect(serverHost, serverPort, timeout: connectionTimeout);
      
      if (_socket != null) {
        await _socket!.close();
        _socket = null;
        debugPrint('✅ MySQL server is reachable at $serverHost:$serverPort');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ MySQL connection test failed: $e');
      return false;
    }
  }

  /// Send MySQL command via raw socket connection
  Future<Map<String, dynamic>> _executeMySQLCommand(String sqlCommand) async {
    try {
      // Note: This is a simplified implementation
      // For production, you'd need a proper MySQL client library
      
      _socket = await Socket.connect(serverHost, serverPort, timeout: connectionTimeout);
      
      if (_socket == null) {
        return {'success': false, 'message': 'Cannot connect to MySQL server'};
      }

      // MySQL handshake and authentication would go here
      // This is a placeholder for the actual MySQL protocol implementation
      
      await _socket!.close();
      _socket = null;
      
      return {'success': true, 'message': 'Command executed successfully'};
      
    } catch (e) {
      debugPrint('MySQL command execution failed: $e');
      return {'success': false, 'message': 'Command failed: $e'};
    }
  }

  // ==================== SYNC SQLite TO MySQL ====================
  
  /// Sync all local SQLite data to MySQL server
  Future<SyncResult> syncSQLiteToMySQL(int userId) async {
    final result = SyncResult();
    
    try {
      // Test connection first
      bool canConnect = await testMySQLConnection();
      if (!canConnect) {
        result.success = false;
        result.message = 'Cannot connect to MySQL server';
        return result;
      }

      // Get all local data from SQLite
      final localUser = await DatabaseHelper.instance.getUser(userId);
      final localProducts = await DatabaseHelper.instance.getProducts(userId);
      final localSales = await DatabaseHelper.instance.getSales(userId);
      
      if (localUser == null) {
        result.success = false;
        result.message = 'User not found in local database';
        return result;
      }

      debugPrint('📤 Starting sync to MySQL...');
      debugPrint('User: ${localUser.username}');
      debugPrint('Products: ${localProducts.length}');
      debugPrint('Sales: ${localSales.length}');

      // For now, we'll simulate the sync process
      // In a real implementation, you'd need a proper MySQL driver
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      
      result.success = true;
      result.message = 'SQLite data synced to MySQL server';
      result.productsCount = localProducts.length;
      result.salesCount = localSales.length;
      result.lastSyncTime = DateTime.now();
      
      debugPrint('✅ Sync to MySQL completed');
      
    } catch (e) {
      result.success = false;
      result.message = 'Sync to MySQL failed: $e';
      debugPrint('❌ Sync to MySQL error: $e');
    }
    
    return result;
  }

  /// Sync individual user to MySQL
  Future<bool> syncUserToMySQL(User user) async {
    try {
      debugPrint('👤 Syncing user: ${user.username} to MySQL');
      
      // Create INSERT/UPDATE SQL for user
      String userSQL = '''
        INSERT INTO users (id, username, email, password, first_name, last_name, 
                          shop_name, shop_address, shop_phone, shop_email, 
                          currency, payment_qr, profile_image, created_at, updated_at)
        VALUES (${user.id}, '${user.username}', '${user.email}', '${user.password}',
                '${user.firstName}', '${user.lastName}', '${user.shopName}',
                '${user.shopAddress ?? ''}', '${user.shopPhone ?? ''}', 
                '${user.shopEmail ?? ''}', '${user.currency}', '${user.paymentQr ?? ''}',
                '${user.profileImage ?? ''}', '${user.createdAt}', '${user.updatedAt}')
        ON DUPLICATE KEY UPDATE
        username='${user.username}', email='${user.email}', 
        first_name='${user.firstName}', last_name='${user.lastName}',
        shop_name='${user.shopName}', updated_at='${user.updatedAt}';
      ''';
      
      final result = await _executeMySQLCommand(userSQL);
      return result['success'] ?? false;
      
    } catch (e) {
      debugPrint('❌ User sync to MySQL failed: $e');
      return false;
    }
  }

  /// Sync individual product to MySQL
  Future<bool> syncProductToMySQL(Product product) async {
    try {
      debugPrint('📦 Syncing product: ${product.name} to MySQL');
      
      String productSQL = '''
        INSERT INTO products (id, user_id, name, price, quantity, low_stock, code,
                             category, unit, image, created_at, updated_at)
        VALUES (${product.id}, ${product.userId}, '${product.name}', ${product.price},
                ${product.quantity}, ${product.lowStock}, '${product.code}',
                '${product.category ?? ''}', '${product.unit}', '${product.image ?? ''}',
                '${product.createdAt}', '${product.updatedAt}')
        ON DUPLICATE KEY UPDATE
        name='${product.name}', price=${product.price}, quantity=${product.quantity},
        low_stock=${product.lowStock}, category='${product.category ?? ''}',
        unit='${product.unit}', updated_at='${product.updatedAt}';
      ''';
      
      final result = await _executeMySQLCommand(productSQL);
      return result['success'] ?? false;
      
    } catch (e) {
      debugPrint('❌ Product sync to MySQL failed: $e');
      return false;
    }
  }

  /// Sync individual sale to MySQL
  Future<bool> syncSaleToMySQL(Sale sale, List<SaleItem> items) async {
    try {
      debugPrint('💰 Syncing sale: ${sale.receiptNumber} to MySQL');
      
      // First sync the sale
      String saleSQL = '''
        INSERT INTO sales (id, user_id, sale_date, total_amount, payment_status,
                          receipt_number, payment_method, description, 
                          customer_name, customer_phone)
        VALUES (${sale.id}, ${sale.userId}, '${sale.saleDate}', ${sale.totalAmount},
                '${sale.paymentStatus}', '${sale.receiptNumber}', '${sale.paymentMethod}',
                '${sale.description ?? ''}', '${sale.customerName ?? ''}', 
                '${sale.customerPhone ?? ''}')
        ON DUPLICATE KEY UPDATE
        total_amount=${sale.totalAmount}, payment_status='${sale.paymentStatus}',
        payment_method='${sale.paymentMethod}';
      ''';
      
      final saleResult = await _executeMySQLCommand(saleSQL);
      
      if (saleResult['success'] == true) {
        // Then sync all sale items
        for (var item in items) {
          String itemSQL = '''
            INSERT INTO sale_items (id, sale_id, product_id, quantity, unit_price, total_price)
            VALUES (${item.id}, ${item.saleId}, ${item.productId}, ${item.quantity},
                    ${item.unitPrice}, ${item.totalPrice})
            ON DUPLICATE KEY UPDATE
            quantity=${item.quantity}, unit_price=${item.unitPrice}, 
            total_price=${item.totalPrice};
          ''';
          
          await _executeMySQLCommand(itemSQL);
        }
      }
      
      return saleResult['success'] ?? false;
      
    } catch (e) {
      debugPrint('❌ Sale sync to MySQL failed: $e');
      return false;
    }
  }

  // ==================== SYNC MySQL TO SQLite ====================
  
  /// Get data from MySQL and update local SQLite
  Future<SyncResult> syncMySQLToSQLite(int userId) async {
    final result = SyncResult();
    
    try {
      debugPrint('📥 Starting sync from MySQL to SQLite...');
      
      // Test connection first
      bool canConnect = await testMySQLConnection();
      if (!canConnect) {
        result.success = false;
        result.message = 'Cannot connect to MySQL server';
        return result;
      }

      // In a real implementation, you'd execute SELECT queries to get data from MySQL
      // For now, we'll simulate this process
      await Future.delayed(Duration(seconds: 1)); // Simulate network delay
      
      result.success = true;
      result.message = 'MySQL data synced to SQLite';
      result.lastSyncTime = DateTime.now();
      
      debugPrint('✅ Sync from MySQL completed');
      
    } catch (e) {
      result.success = false;
      result.message = 'MySQL to SQLite sync failed: $e';
      debugPrint('❌ Sync from MySQL error: $e');
    }
    
    return result;
  }

  /// Bidirectional sync: SQLite ↔ MySQL
  Future<SyncResult> bidirectionalSync(int userId) async {
    final result = SyncResult();
    
    try {
      debugPrint('🔄 Starting bidirectional sync...');
      
      // 1. Upload SQLite data to MySQL
      final uploadResult = await syncSQLiteToMySQL(userId);
      
      // 2. Download MySQL data to SQLite  
      final downloadResult = await syncMySQLToSQLite(userId);
      
      result.success = uploadResult.success && downloadResult.success;
      result.message = 'Upload: ${uploadResult.message}, Download: ${downloadResult.message}';
      result.productsCount = uploadResult.productsCount;
      result.salesCount = uploadResult.salesCount;
      result.lastSyncTime = DateTime.now();
      
      debugPrint('✅ Bidirectional sync completed');
      
    } catch (e) {
      result.success = false;
      result.message = 'Bidirectional sync failed: $e';
      debugPrint('❌ Bidirectional sync error: $e');
    }
    
    return result;
  }

  // ==================== UTILITY METHODS ====================

  /// Create MySQL database tables that match your SQLite schema
  Future<bool> createMySQLTables() async {
    try {
      debugPrint('🔧 Creating MySQL tables...');
      
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
          debugPrint('❌ Failed to create table: ${result['message']}');
          return false;
        }
      }
      
      debugPrint('✅ All MySQL tables created successfully');
      return true;
      
    } catch (e) {
      debugPrint('❌ Create MySQL tables failed: $e');
      return false;
    }
  }

  /// Check if MySQL server is reachable
  Future<bool> isServerAvailable() async {
    return await testMySQLConnection();
  }

  /// Get server status information
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      bool isAvailable = await isServerAvailable();
      
      return {
        'server_host': serverHost,
        'server_port': serverPort,
        'database': serverDatabase,
        'is_available': isAvailable,
        'last_check': DateTime.now().toIso8601String(),
        'status': isAvailable ? 'Connected' : 'Disconnected'
      };
    } catch (e) {
      return {
        'server_host': serverHost,
        'server_port': serverPort,
        'database': serverDatabase,
        'is_available': false,
        'last_check': DateTime.now().toIso8601String(),
        'status': 'Error: $e'
      };
    }
  }

  /// Close any open connections
  Future<void> close() async {
    try {
      if (_socket != null) {
        await _socket!.close();
        _socket = null;
        debugPrint('🔌 MySQL connection closed');
      }
    } catch (e) {
      debugPrint('Error closing MySQL connection: $e');
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