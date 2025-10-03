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
      final result = await DatabaseHelper.instance.deleteProduct(productId, userId);
      if (result == 1) {
        _products.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }
      return false;
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
      // Fix: Always update quantity when adding same product
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
  Future<bool> completeSale(int userId, String username, {String paymentMethod = 'QR'}) async {
    if (_cartItems.isEmpty) return false;

    try {
      final receiptNumber = AppUtils.generateReceiptNumber(username);
      final sale = Sale(
        userId: userId,
        saleDate: AppUtils.toThaiTime(DateTime.now()), // Use Thai time
        totalAmount: cartTotal,
        receiptNumber: receiptNumber,
        paymentStatus: 'Completed',
        paymentMethod: paymentMethod, // Fix: Use the actual payment method
      );

      final saleItems = _cartItems.map((cartItem) => 
        SaleItem.fromCartItem(cartItem, 0) // saleId will be set in database
      ).toList();

      await DatabaseHelper.instance.createSale(sale, saleItems);
      
      // Update local product quantities and sync to database
      for (var cartItem in _cartItems) {
        final productIndex = _products.indexWhere((p) => p.id == cartItem.product.id);
        if (productIndex != -1) {
          final oldQuantity = _products[productIndex].quantity;
          final newQuantity = oldQuantity - cartItem.quantity;
          
          // Add inventory record for the sale
          await addInventoryRecord(
            userId: userId,
            productId: cartItem.product.id!,
            changeType: 'SALE',
            stockBefore: oldQuantity,
            stockAfter: newQuantity,
            notes: 'Sold ${cartItem.quantity} items of ${cartItem.product.name}',
          );
          
          final updatedProduct = _products[productIndex].copyWith(
            quantity: newQuantity,
          );
          
          // Update in local list
          _products[productIndex] = updatedProduct;
          
          // Update in database
          await DatabaseHelper.instance.updateProduct(updatedProduct);
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
        _error = '⚠️ ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ - ทำงานในโหมดจำกัด'; // Cannot connect to server - working in limited mode
        _sales = []; // Empty list when offline
        notifyListeners();
        return;
      }
      
      _sales = await DatabaseHelper.instance.getSales(userId);
      notifyListeners();
    } catch (e) {
      _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูลการขาย: ${e.toString()}'; // Error loading sales data
      _sales = []; // Empty list on error
      notifyListeners();
      debugPrint('❌ Sales loading failed: $e');
    }
  }

  Future<List<Product>> getLowStockProducts(int userId) async {
    try {
      return await DatabaseHelper.instance.getLowStockProducts(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Advanced Analytics Methods

  /// Get sales data grouped by hour for peak hour analysis
  Future<Map<String, dynamic>> getSalesByHour(int userId, DateTime startDate, DateTime endDate) async {
    try {
      return await DatabaseHelper.instance.getSalesByHour(userId, startDate, endDate);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'hourlyData': []};
    }
  }

  /// Get sales data grouped by day for trend analysis
  Future<Map<String, dynamic>> getSalesByDay(int userId, DateTime startDate, DateTime endDate) async {
    try {
      return await DatabaseHelper.instance.getSalesByDay(userId, startDate, endDate);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'dailyData': []};
    }
  }

  /// Get top selling products by revenue
  Future<List<Map<String, dynamic>>> getTopSellingProducts(int userId, DateTime startDate, DateTime endDate, {int limit = 10}) async {
    try {
      return await DatabaseHelper.instance.getTopSellingProducts(userId, startDate, endDate, limit: limit);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get customer purchase history
  Future<List<Map<String, dynamic>>> getCustomerPurchaseHistory(int userId, {int limit = 50}) async {
    try {
      return await DatabaseHelper.instance.getCustomerPurchaseHistory(userId, limit: limit);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get sale items with product details for a specific sale
  Future<List<SaleItem>> getSaleItemsWithProducts(int saleId) async {
    try {
      return await DatabaseHelper.instance.getSaleItemsWithProducts(saleId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Add inventory record for stock movement tracking
  Future<bool> addInventoryRecord({
    required int userId,
    required int productId,
    required String changeType,
    required int stockBefore,
    required int stockAfter,
    int? referenceId,
    String? notes,
  }) async {
    try {
      return await DatabaseHelper.instance.addInventoryRecord(
        userId: userId,
        productId: productId,
        changeType: changeType,
        stockBefore: stockBefore,
        stockAfter: stockAfter,
        referenceId: referenceId,
        notes: notes,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get inventory movement data for stock analysis
  Future<Map<String, dynamic>> getInventoryMovement(int userId, DateTime startDate, DateTime endDate) async {
    try {
      return await DatabaseHelper.instance.getInventoryMovement(userId, startDate, endDate);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'inventoryData': []};
    }
  }

  /// Get reorder suggestions based on sales velocity
  Future<List<Map<String, dynamic>>> getReorderSuggestions(int userId) async {
    try {
      return await DatabaseHelper.instance.getReorderSuggestions(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get sales trends and growth analysis
  Future<Map<String, dynamic>> getSalesTrends(int userId, DateTime startDate, DateTime endDate) async {
    try {
      // Get current period data
      final currentPeriodData = await DatabaseHelper.instance.getSalesByDay(userId, startDate, endDate);
      
      // Calculate previous period dates (same duration but one period back)
      final duration = endDate.difference(startDate);
      final previousStartDate = startDate.subtract(duration);
      final previousEndDate = endDate.subtract(duration);
      
      // Get previous period data
      final previousPeriodData = await DatabaseHelper.instance.getSalesByDay(userId, previousStartDate, previousEndDate);
      
      // Calculate growth
      final currentRevenue = (currentPeriodData['dailyData'] as List)
          .fold<double>(0.0, (sum, item) => sum + (item['total_revenue'] as double));
      
      final previousRevenue = (previousPeriodData['dailyData'] as List)
          .fold<double>(0.0, (sum, item) => sum + (item['total_revenue'] as double));
      
      final growthRate = previousRevenue > 0 
          ? ((currentRevenue - previousRevenue) / previousRevenue) * 100 
          : 0.0;
      
      return {
        'currentPeriodData': currentPeriodData,
        'previousPeriodData': previousPeriodData,
        'currentRevenue': currentRevenue,
        'previousRevenue': previousRevenue,
        'growthRate': growthRate,
      };
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'currentPeriodData': {'dailyData': []},
        'previousPeriodData': {'dailyData': []},
        'currentRevenue': 0.0,
        'previousRevenue': 0.0,
        'growthRate': 0.0,
      };
    }
  }

  /// Get product performance analysis
  Future<List<Map<String, dynamic>>> getProductPerformance(int userId, DateTime startDate, DateTime endDate, {int limit = 20}) async {
    try {
      return await DatabaseHelper.instance.getTopSellingProducts(userId, startDate, endDate, limit: limit);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Get customer segmentation data
  Future<Map<String, dynamic>> getCustomerSegmentation(int userId, {int limit = 100}) async {
    try {
      final customerData = await DatabaseHelper.instance.getCustomerPurchaseHistory(userId, limit: limit);
      
      // Segment customers by spending
      double highValueThreshold = 5000; // High value customers spend more than this
      double mediumValueThreshold = 1000; // Medium value customers spend more than this
      
      int highValueCount = 0;
      int mediumValueCount = 0;
      int lowValueCount = 0;
      
      double totalSpent = 0;
      
      for (var customer in customerData) {
        final spent = customer['total_spent'] as double? ?? 0.0;
        totalSpent += spent;
        
        if (spent >= highValueThreshold) {
          highValueCount++;
        } else if (spent >= mediumValueThreshold) {
          mediumValueCount++;
        } else {
          lowValueCount++;
        }
      }
      
      return {
        'segments': {
          'highValue': highValueCount,
          'mediumValue': mediumValueCount,
          'lowValue': lowValueCount,
        },
        'totalCustomers': customerData.length,
        'averageSpentPerCustomer': customerData.isNotEmpty ? totalSpent / customerData.length : 0.0,
        'totalRevenue': totalSpent,
      };
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {
        'segments': {
          'highValue': 0,
          'mediumValue': 0,
          'lowValue': 0,
        },
        'totalCustomers': 0,
        'averageSpentPerCustomer': 0.0,
        'totalRevenue': 0.0,
      };
    }
  }

  // Background sync methods
  Future<void> _syncProductToServer(Product product) async {
    try {
      // In a real implementation, you would send the product to your server
      // This is a placeholder for the sync functionality
      debugPrint('Syncing product ${product.name} to server');
    } catch (e) {
      debugPrint('Failed to sync product to server: $e');
    }
  }

  Future<void> _syncSaleToServer(Sale sale, List<SaleItem> saleItems) async {
    try {
      // In a real implementation, you would send the sale and sale items to your server
      // This is a placeholder for the sync functionality
      debugPrint('Syncing sale ${sale.receiptNumber} to server');
    } catch (e) {
      debugPrint('Failed to sync sale to server: $e');
    }
  }
}