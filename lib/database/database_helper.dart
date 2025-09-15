// FILE: lib/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../core/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('${AppConstants.dbName}');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE ${AppConstants.usersTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        shop_name TEXT NOT NULL,
        shop_address TEXT,
        shop_phone TEXT,
        shop_email TEXT,
        currency TEXT DEFAULT 'THB',
        payment_qr TEXT,
        profile_image TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE ${AppConstants.productsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        low_stock INTEGER DEFAULT 5,
        code TEXT NOT NULL,
        category TEXT,
        unit TEXT DEFAULT 'pcs',
        image TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES ${AppConstants.usersTable} (id) ON DELETE CASCADE,
        UNIQUE(user_id, code)
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE ${AppConstants.salesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        sale_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        total_amount REAL NOT NULL,
        payment_status TEXT DEFAULT 'Completed',
        receipt_number TEXT NOT NULL,
        payment_method TEXT DEFAULT 'QR',
        description TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        FOREIGN KEY (user_id) REFERENCES ${AppConstants.usersTable} (id) ON DELETE CASCADE,
        UNIQUE(user_id, receipt_number)
      )
    ''');

    // Sale items table
    await db.execute('''
      CREATE TABLE ${AppConstants.saleItemsTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES ${AppConstants.salesTable} (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.productsTable} (id)
      )
    ''');

    // Inventories table
    await db.execute('''
      CREATE TABLE ${AppConstants.inventoriesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        change_type TEXT NOT NULL,
        stock_before INTEGER NOT NULL,
        stock_after INTEGER NOT NULL,
        reference_id INTEGER,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES ${AppConstants.usersTable} (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES ${AppConstants.productsTable} (id)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_products_user_id ON ${AppConstants.productsTable}(user_id)');
    await db.execute('CREATE INDEX idx_sales_user_id ON ${AppConstants.salesTable}(user_id)');
    await db.execute('CREATE INDEX idx_inventories_user_id ON ${AppConstants.inventoriesTable}(user_id)');
  }

  // User operations
  Future<User> createUser(User user) async {
    final db = await instance.database;
    final id = await db.insert(AppConstants.usersTable, user.toMap());
    return user.copyWith(id: id);
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.usersTable,
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.usersTable,
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUser(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.database;
    return db.update(
      AppConstants.usersTable,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Product operations
  Future<Product> createProduct(Product product) async {
    final db = await instance.database;
    final id = await db.insert(AppConstants.productsTable, product.toMap());
    return product.copyWith(id: id);
  }

  Future<List<Product>> getProducts(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.productsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<Product?> getProductByCode(String code, int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.productsTable,
      where: 'code = ? AND user_id = ?',
      whereArgs: [code, userId],
    );

    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return db.update(
      AppConstants.productsTable,
      product.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [product.id, product.userId],
    );
  }

  Future<int> deleteProduct(int id, int userId) async {
    final db = await instance.database;
    return db.delete(
      AppConstants.productsTable,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // Sale operations
  Future<Sale> createSale(Sale sale, List<SaleItem> items) async {
    final db = await instance.database;
    
    await db.transaction((txn) async {
      // Insert sale
      final saleId = await txn.insert(AppConstants.salesTable, sale.toMap());
      
      // Insert sale items and update product quantities
      for (var item in items) {
        await txn.insert(AppConstants.saleItemsTable, item.copyWith(saleId: saleId).toMap());
        
        // Update product quantity
        await txn.rawUpdate('''
          UPDATE ${AppConstants.productsTable} 
          SET quantity = quantity - ? 
          WHERE id = ?
        ''', [item.quantity, item.productId]);
      }
    });
    
    return sale;
  }

  Future<List<Sale>> getSales(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      AppConstants.salesTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'sale_date DESC',
    );

    return List.generate(maps.length, (i) => Sale.fromMap(maps[i]));
  }

  Future<List<Sale>> getSalesToday(int userId) async {
    final db = await instance.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final maps = await db.query(
      AppConstants.salesTable,
      where: 'user_id = ? AND sale_date >= ? AND sale_date < ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'sale_date DESC',
    );

    return List.generate(maps.length, (i) => Sale.fromMap(maps[i]));
  }

  Future<double> getTotalSalesToday(int userId) async {
    final sales = await getSalesToday(userId);
    return sales.fold<double>(0.0, (double sum, Sale sale) => sum + sale.totalAmount);
  }

  Future<List<Product>> getLowStockProducts(int userId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT * FROM ${AppConstants.productsTable}
      WHERE user_id = ? AND quantity <= low_stock
      ORDER BY quantity ASC
    ''', [userId]);

    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}