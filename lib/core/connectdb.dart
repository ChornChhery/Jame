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
// Removed circular import: '../database/database_helper.dart'

class ConnectDB {
  static final ConnectDB _instance = ConnectDB._internal();
  factory ConnectDB() => _instance;
  ConnectDB._internal();

  // ==================== MySQL Server Configuration from .env ====================
  // All values must be set in .env file - no fallback values for security
  static String get serverHost {
    final host = dotenv.env['DB_HOST'];
    if (host == null || host.isEmpty) {
      throw Exception('DB_HOST not found in .env file');
    }
    return host;
  }
  
  static int get serverPort {
    // Use default MySQL port 3306 like PHP PDO
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
  static Duration get connectionTimeout => Duration(seconds: 10); // Standard timeout for remote servers per specification
  
  MySqlConnection? _connection;
  Socket? _socket;

  // ==================== CONFIGURATION VALIDATION ====================
  
  /// Check if configuration is valid
  bool _isConfigurationValid() {
    try {
      // Try to access all required environment variables
      final host = serverHost;
      final port = serverPort;
      final user = serverUser;
      final password = serverPassword;
      final database = serverDatabase;
      
      // All values are successfully retrieved from .env
      return host.isNotEmpty && 
             user.isNotEmpty && 
             password.isNotEmpty && 
             database.isNotEmpty &&
             port > 0 && port < 65536;
    } catch (e) {
      debugPrint('❌ Configuration validation failed: $e');
      return false;
    }
  }
  
  /// Get configuration status
  Map<String, dynamic> getConfigStatus() {
    try {
      final host = serverHost;
      final port = serverPort;
      final user = serverUser;
      final database = serverDatabase;
      // Don't access password here for security
      
      return {
        'env_loaded': dotenv.env.isNotEmpty,
        'config_valid': _isConfigurationValid(),
        'host_configured': host.isNotEmpty,
        'user_configured': user.isNotEmpty,
        'password_configured': dotenv.env.containsKey('MYSQL_PASSWORD'),
        'database_configured': database.isNotEmpty,
        'port_configured': port > 0 && port < 65536,
        'connection_string': 'mysql://$user:****@$host:$port/$database',
      };
    } catch (e) {
      return {
        'env_loaded': dotenv.env.isNotEmpty,
        'config_valid': false,
        'error': e.toString(),
        'connection_string': 'Configuration error - check .env file',
      };
    }
  }
  
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
  
  /// Get or create MySQL connection with timeout handling
  Future<MySqlConnection> _getConnection() async {
    try {
      if (_connection == null) {
        debugPrint('🔌 Creating new MySQL connection...');
        // Use standard timeout for remote servers per specification
        _connection = await MySqlConnection.connect(_connectionSettings)
            .timeout(Duration(seconds: 10));
        debugPrint('✅ MySQL connection established');
      }
      return _connection!;
    } catch (e) {
      debugPrint('❌ MySQL connection failed: $e');
      _connection = null; // Reset connection on failure
      rethrow;
    }
  }
  
  /// Test direct connection to MySQL server with enhanced diagnostics and non-blocking operation
  Future<bool> testMySQLConnection({int maxRetries = 2}) async {
    return await _performConnectionTest(maxRetries);
  }
  
  /// Internal connection test that can be run in background
  Future<bool> _performConnectionTest(int maxRetries) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Validate configuration first
        if (!_isConfigurationValid()) {
          debugPrint('❌ MySQL configuration is invalid');
          debugPrint('Config status: ${getConfigStatus()}');
          return false;
        }
        
        debugPrint('🌐 Connecting to remote MySQL server: ${serverHost}:${serverPort} (Attempt $attempt/$maxRetries)');
        
        // Create connection settings matching PHP PDO configuration
        final connectionSettings = ConnectionSettings(
          host: serverHost,
          port: serverPort, // Default 3306 like PHP
          user: serverUser,
          password: serverPassword,
          db: serverDatabase,
          timeout: Duration(seconds: 10), // Standard timeout per specification
        );
        
        // Test connection with timeout and immediate cleanup
        final connection = await Future.any([
          MySqlConnection.connect(connectionSettings),
          Future.delayed(Duration(seconds: 10), () => throw TimeoutException('Connection timeout', Duration(seconds: 10)))
        ]);
        
        await connection.close();
        
        debugPrint('✅ Remote MySQL server connection successful on attempt $attempt');
        return true;
        
      } catch (e) {
        final errorMessage = e.toString();
        final truncatedError = errorMessage.length > 100 ? errorMessage.substring(0, 100) + '...' : errorMessage;
        debugPrint('❌ MySQL connection attempt $attempt failed: $truncatedError');
        
        if (attempt == maxRetries) {
          // Provide detailed diagnostics on final failure
          debugPrint('🔍 Connection Details:');
          try {
            debugPrint('   Host: ${serverHost}');
            debugPrint('   Port: ${serverPort}');
            debugPrint('   Database: ${serverDatabase}');
            debugPrint('   User: ${serverUser}');
          } catch (configError) {
            debugPrint('   Configuration Error: $configError');
          }
          
          debugPrint('💡 Troubleshooting Tips:');
          if (errorMessage.contains('timeout') || errorMessage.contains('Timeout')) {
            debugPrint('   - Check if connected to PSU network/VPN');
            debugPrint('   - University firewall may block external connections');
            debugPrint('   - Try connecting from university campus');
            debugPrint('   - Mobile networks may have stricter timeouts');
          } else if (errorMessage.contains('Connection refused')) {
            debugPrint('   - Verify server host and port are correct');
            debugPrint('   - Check if MySQL service is running');
          } else if (errorMessage.contains('Access denied')) {
            debugPrint('   - Check username and password in .env file');
            debugPrint('   - Verify database permissions');
          }
          debugPrint('   - Test phpMyAdmin access: https://mysql.mcs.psu.ac.th/');
          debugPrint('   - Contact PSU IT for mobile app access permissions');
          debugPrint('   - Current resolved IP: Likely university internal network');
          
        } else {
          // Brief delay between retries
          await Future.delayed(Duration(milliseconds: 300));
        }
      }
    }
    return false;
  }

  /// Execute MySQL command with proper SQL execution
  Future<Map<String, dynamic>> _executeMySQLCommand(String sqlCommand) async {
    try {
      final queryPreview = sqlCommand.length > 50 ? sqlCommand.substring(0, 50) + '...' : sqlCommand;
      debugPrint('📤 Executing SQL: $queryPreview');
      
      final connection = await _getConnection();
      
      // Execute the SQL command
      final result = await connection.query(sqlCommand);
      
      debugPrint('✅ SQL executed successfully, affected rows: ${result.affectedRows}');
      return {
        'success': true, 
        'message': 'Command executed successfully',
        'affected_rows': result.affectedRows,
        'insert_id': result.insertId,
      };
      
    } catch (e) {
      debugPrint('❌ MySQL command execution failed: $e');
      return {'success': false, 'message': 'Command failed: $e'};
    }
  }

  // ==================== MYSQL DATABASE OPERATIONS ====================
  
  /// Execute MySQL SELECT query with parameters and return results
  Future<List<Map<String, dynamic>>> executeSelectQuery(String query, [List<dynamic>? parameters]) async {
    try {
      final queryPreview = query.length > 50 ? query.substring(0, 50) + '...' : query;
      debugPrint('📥 Executing SELECT: $queryPreview');
      
      final connection = await _getConnection();
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
      
      debugPrint('✅ SELECT query returned ${rows.length} rows');
      return rows;
      
    } catch (e) {
      debugPrint('❌ SELECT query failed: $e');
      throw Exception('SELECT query failed: $e');
    }
  }
  
  /// Execute MySQL UPDATE/INSERT/DELETE query with parameters
  Future<bool> executeUpdateQuery(String query, [List<dynamic>? parameters]) async {
    try {
      final queryPreview = query.length > 50 ? query.substring(0, 50) + '...' : query;
      debugPrint('📤 Executing UPDATE query: $queryPreview');
      
      final connection = await _getConnection();
      final result = await connection.query(query, parameters);
      
      debugPrint('✅ UPDATE query executed, affected rows: ${result.affectedRows}');
      return result.affectedRows != null && result.affectedRows! > 0;
      
    } catch (e) {
      debugPrint('❌ UPDATE query failed: $e');
      return false;
    }
  }

  /// Sync individual user to MySQL with parameterized queries
  Future<bool> syncUserToMySQL(User user) async {
    try {
      debugPrint('👤 Syncing user: ${user.username} to MySQL');
      
      final connection = await _getConnection();
      
      // Use parameterized query to prevent SQL injection
      final result = await connection.query(
        '''
        INSERT INTO users (id, username, email, password, first_name, last_name, 
                          shop_name, shop_address, shop_phone, shop_email, 
                          currency, payment_qr, profile_image, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        username=VALUES(username), email=VALUES(email), 
        first_name=VALUES(first_name), last_name=VALUES(last_name),
        shop_name=VALUES(shop_name), updated_at=VALUES(updated_at)
        ''',
        [
          user.id,
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
      
      debugPrint('✅ User synced successfully, affected rows: ${result.affectedRows}');
      return result.affectedRows != null && result.affectedRows! > 0;
      
    } catch (e) {
      debugPrint('❌ User sync to MySQL failed: $e');
      return false;
    }
  }

  /// Sync individual product to MySQL with parameterized queries
  Future<bool> syncProductToMySQL(Product product) async {
    try {
      debugPrint('📦 Syncing product: ${product.name} to MySQL');
      
      final connection = await _getConnection();
      
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
          product.createdAt,
          product.updatedAt,
        ],
      );
      
      debugPrint('✅ Product synced successfully, affected rows: ${result.affectedRows}');
      return result.affectedRows != null && result.affectedRows! > 0;
      
    } catch (e) {
      debugPrint('❌ Product sync to MySQL failed: $e');
      return false;
    }
  }

  /// Sync individual sale to MySQL with parameterized queries
  Future<bool> syncSaleToMySQL(Sale sale, List<SaleItem> items) async {
    try {
      debugPrint('💰 Syncing sale: ${sale.receiptNumber} to MySQL');
      
      final connection = await _getConnection();
      
      // First sync the sale with parameterized query
      final saleResult = await connection.query(
        '''
        INSERT INTO sales (id, user_id, sale_date, total_amount, payment_status,
                          receipt_number, payment_method, description, 
                          customer_name, customer_phone)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
        total_amount=VALUES(total_amount), payment_status=VALUES(payment_status),
        payment_method=VALUES(payment_method)
        ''',
        [
          sale.id,
          sale.userId,
          sale.saleDate,
          sale.totalAmount,
          sale.paymentStatus,
          sale.receiptNumber,
          sale.paymentMethod,
          sale.description ?? '',
          sale.customerName ?? '',
          sale.customerPhone ?? '',
        ],
      );
      
      if (saleResult.affectedRows != null && saleResult.affectedRows! > 0) {
        // Then sync all sale items with parameterized queries
        for (var item in items) {
          await connection.query(
            '''
            INSERT INTO sale_items (id, sale_id, product_id, quantity, unit_price, total_price)
            VALUES (?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            quantity=VALUES(quantity), unit_price=VALUES(unit_price), 
            total_price=VALUES(total_price)
            ''',
            [
              item.id,
              item.saleId,
              item.productId,
              item.quantity,
              item.unitPrice,
              item.totalPrice,
            ],
          );
        }
      }
      
      debugPrint('✅ Sale synced successfully, affected rows: ${saleResult.affectedRows}');
      return saleResult.affectedRows != null && saleResult.affectedRows! > 0;
      
    } catch (e) {
      debugPrint('❌ Sale sync to MySQL failed: $e');
      return false;
    }
  }

  // ==================== MYSQL DATABASE TESTING ====================

  /// Test MySQL database operations
  Future<SyncResult> testDatabaseOperations(int userId) async {
    final result = SyncResult();
    
    try {
      debugPrint('🔄 Testing MySQL database operations...');
      
      // Test connection first
      bool canConnect = await testMySQLConnection();
      if (!canConnect) {
        result.success = false;
        result.message = 'Cannot connect to MySQL server';
        return result;
      }

      // Test table creation
      bool tablesCreated = await createMySQLTables();
      if (!tablesCreated) {
        result.success = false;
        result.message = 'Failed to create MySQL tables';
        return result;
      }
      
      result.success = true;
      result.message = 'MySQL database operations test completed successfully';
      result.lastSyncTime = DateTime.now();
      
      debugPrint('✅ Database operations test completed');
      
    } catch (e) {
      result.success = false;
      result.message = 'Database operations test failed: $e';
      debugPrint('❌ Database operations test error: $e');
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
      
      final host = serverHost;
      final port = serverPort;
      final database = serverDatabase;
      final user = serverUser;
      
      return {
        'server_host': host,
        'server_port': port,
        'database': database,
        'is_available': isAvailable,
        'last_check': DateTime.now().toIso8601String(),
        'status': isAvailable ? 'Connected' : 'Disconnected',
        'config_valid': _isConfigurationValid(),
        'env_loaded': dotenv.env.isNotEmpty,
        'connection_string': 'mysql://$user:****@$host:$port/$database',
        'config_status': getConfigStatus(),
      };
    } catch (e) {
      return {
        'server_host': 'Configuration Error',
        'server_port': 0,
        'database': 'Configuration Error',
        'is_available': false,
        'last_check': DateTime.now().toIso8601String(),
        'status': 'Configuration Error: $e',
        'config_valid': false,
        'env_loaded': dotenv.env.isNotEmpty,
        'connection_string': 'Check .env file configuration',
        'config_status': getConfigStatus(),
      };
    }
  }

  /// Close any open connections
  Future<void> close() async {
    try {
      if (_connection != null) {
        await _connection!.close();
        _connection = null;
        debugPrint('🔌 MySQL connection closed');
      }
      if (_socket != null) {
        await _socket!.close();
        _socket = null;
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