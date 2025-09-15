// FILE: lib/providers/app_provider.dart
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../database/database_helper.dart';
import '../core/utils.dart';

class AppProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  List<Sale> _sales = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<CartItem> get cartItems => _cartItems;
  List<Sale> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  double get cartTotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Product operations
  Future<void> loadProducts(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await DatabaseHelper.instance.getProducts(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      final newProduct = await DatabaseHelper.instance.createProduct(product);
      _products.add(newProduct);
      notifyListeners();
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
      _sales = await DatabaseHelper.instance.getSales(userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
}