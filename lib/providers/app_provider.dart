// FILE: lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../database/database_helper.dart';
import '../core/utils.dart';
import '../core/connectdb.dart';

class AppProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;
  final ConnectDB _connectDB = ConnectDB(); // Add server connection

  List<Product> get products => _products;
  List<CartItem> get cartItems => _cartItems;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get cartTotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Product operations with graceful MySQL failure handling
  Future<void> loadProducts(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Test MySQL connection first
      final connectionAvailable = await _connectDB.testMySQLConnection();
      if (!connectionAvailable) {
        _error = '⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ - ทำงานในโหมดจำกัด'; // Cannot connect to server - working in limited mode
        _products = []; // Empty list when offline
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      _products = await DatabaseHelper.instance.getProducts(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูลสินค้า: ${e.toString()}'; // Error loading product data
      _products = []; // Empty list on error
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Product loading failed: $e');
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      // 1. Add to local database first
      final newProduct = await DatabaseHelper.instance.createProduct(product);
      _products.add(newProduct);
      notifyListeners();
      
      // 2. Sync to server in background
      _syncProductToServer(newProduct);
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await DatabaseHelper.instance.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int productId, int userId) async {
    try {
      await DatabaseHelper.instance.deleteProduct(productId, userId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Product?> getProductByCode(String code, int userId) async {
    try {
      return await DatabaseHelper.instance.getProductByCode(code, userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Cart operations
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  // Sale operations
  Future<bool> completeSale(int userId, String username) async {
    if (_cartItems.isEmpty) return false;

    try {
      final receiptNumber = AppUtils.generateReceiptNumber(username);
      final sale = Sale(
        userId: userId,
        saleDate: DateTime.now(),
        totalAmount: cartTotal,
        receiptNumber: receiptNumber,
        paymentStatus: 'Completed',
        paymentMethod: 'QR',
      );

      final saleItems = _cartItems.map((cartItem) => 
        SaleItem.fromCartItem(cartItem, 0) // saleId will be set in database
      ).toList();

      await DatabaseHelper.instance.createSale(sale, saleItems);
      
      // Update local product quantities
      for (var cartItem in _cartItems) {
        final productIndex = _products.indexWhere((p) => p.id == cartItem.product.id);
        if (productIndex != -1) {
          _products[productIndex] = _products[productIndex].copyWith(
            quantity: _products[productIndex].quantity - cartItem.quantity,
          );
        }
      }
      
      // Sync sale to server in background
      _syncSaleToServer(sale, saleItems);

      clearCart();
      await loadSales(userId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadSales(int userId) async {
    try {
      // Test MySQL connection first
      final connectionAvailable = await _connectDB.testMySQLConnection();
      if (!connectionAvailable) {
        debugPrint('⚠️ MySQL not available - sales data unavailable in limited mode');
        _sales = []; // Empty list when offline
        notifyListeners();
        return;
      }
      
      _sales = await DatabaseHelper.instance.getSales(userId);
      notifyListeners();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูลยอดขาย: ${e.toString()}'; // Error loading sales data
      _sales = []; // Empty list on error
      notifyListeners();
      debugPrint('❌ Sales loading failed: $e');
    }
  }

  Future<double> getTodaySales(int userId) async {
    try {
      return await DatabaseHelper.instance.getTotalSalesToday(userId);
    } catch (e) {
      return 0.0;
    }
  }

  Future<List<Product>> getLowStockProducts(int userId) async {
    try {
      return await DatabaseHelper.instance.getLowStockProducts(userId);
    } catch (e) {
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // ==================== SERVER SYNC METHODS ====================
  
  /// Sync single product to server (non-blocking)
  void _syncProductToServer(Product product) async {
    try {
      await _connectDB.syncProductToMySQL(product);
    } catch (e) {
      // Silent fail - server sync is optional
      debugPrint('Product server sync failed: $e');
    }
  }
  
  /// Sync sale to server (non-blocking)
  void _syncSaleToServer(Sale sale, List<SaleItem> items) async {
    try {
      await _connectDB.syncSaleToMySQL(sale, items);
    } catch (e) {
      // Silent fail - server sync is optional
      debugPrint('Sale server sync failed: $e');
    }
  }
  
  /// Manual sync all data with server
  Future<bool> syncWithServer(int userId) async {
    try {
      // Test MySQL database operations since we're now using MySQL directly
      final syncResult = await _connectDB.testDatabaseOperations(userId);
      
      if (!syncResult.success) {
        _error = 'Database operations test failed: ${syncResult.message}';
        notifyListeners();
      }
      
      return syncResult.success;
    } catch (e) {
      _error = 'Database operations test failed: $e';
      notifyListeners();
      return false;
    }
  }
  
  /// Test server connection
  Future<bool> testServerConnection() async {
    try {
      return await _connectDB.testMySQLConnection();
    } catch (e) {
      return false;
    }
  }
}