import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../models/report_models.dart';
import '../models/sale.dart';
import '../services/jame_api.dart';
import '../services/jame_repository.dart';

class AppProvider extends ChangeNotifier {
  AppProvider({JameRepository? repository})
    : _repository = repository ?? JameRepository(api: JameApi());

  final JameRepository _repository;
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  List<Sale> _sales = [];
  final List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<CartItem> get cartItems => _cartItems;
  List<Sale> get sales => _sales;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get unreadNotifications =>
      _notifications.where((notification) => !notification['isRead']).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get cartTotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get cartItemCount =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  Future<void> loadCartItems(int userId) async {
    try {
      _cartItems = await _repository.getCart();
      _error = null;
      notifyListeners();
    } catch (error) {
      _recordError(error);
      rethrow;
    }
  }

  Future<void> loadProducts(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _repository.getProducts();
      _error = null;
    } catch (error) {
      _recordError(error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      final createdProduct = await _repository.createProduct(product);
      _products = [..._products, createdProduct];
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _recordError(error);
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _repository.updateProduct(product);
      final index = _products.indexWhere((item) => item.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _recordError(error);
      return false;
    }
  }

  Future<bool> deleteProduct(int productId, int userId) async {
    try {
      await _repository.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _recordError(error);
      return false;
    }
  }

  Future<Product?> getProductByCode(String code, int userId) async {
    try {
      final product = await _repository.getProductByCode(code);
      _error = null;
      return product;
    } catch (error) {
      _recordError(error);
      rethrow;
    }
  }

  void addToCart(Product product, {int quantity = 1}) {
    if (product.quantity <= 0) return;
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex == -1) {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    } else {
      _cartItems[existingIndex].quantity += quantity;
    }
    notifyListeners();
  }

  void updateCartItemQuantity(int productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;
    if (quantity <= 0) {
      _cartItems.removeAt(index);
    } else {
      _cartItems[index].quantity = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void markNotificationAsRead(int notificationId) {
    final index = _notifications.indexWhere(
      (notification) => notification['id'] == notificationId,
    );
    if (index == -1) return;
    _notifications[index]['isRead'] = true;
    notifyListeners();
  }

  void markAllNotificationsAsRead() {
    for (final notification in _notifications) {
      notification['isRead'] = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void removeNotification(int notificationId) {
    _notifications.removeWhere(
      (notification) => notification['id'] == notificationId,
    );
    notifyListeners();
  }

  Future<void> saveCartItemToDatabase(int userId, CartItem cartItem) async {
    final productId = cartItem.product.id;
    if (productId == null) {
      throw ArgumentError.value(productId, 'cartItem.product.id');
    }
    await _runRequest(
      () => _repository.setCartQuantity(productId, cartItem.quantity),
    );
  }

  Future<void> removeCartItemFromDatabase(int userId, int productId) async {
    await _runRequest(() => _repository.setCartQuantity(productId, 0));
  }

  Future<void> clearCartInDatabase(int userId) async {
    await _runRequest(_repository.clearCart);
  }

  Future<void> addToCartWithPersistence(
    int userId,
    Product product, {
    int quantity = 1,
  }) async {
    if (product.quantity <= 0) return;
    final productId = product.id;
    if (productId == null) {
      throw ArgumentError.value(productId, 'product.id');
    }
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    final newQuantity =
        (index == -1 ? 0 : _cartItems[index].quantity) + quantity;
    await _runRequest(
      () => _repository.setCartQuantity(productId, newQuantity),
    );
    if (index == -1) {
      _cartItems.add(CartItem(product: product, quantity: newQuantity));
    } else {
      _cartItems[index].quantity = newQuantity;
    }
    _error = null;
    notifyListeners();
  }

  Future<void> updateCartItemQuantityWithPersistence(
    int userId,
    int productId,
    int quantity,
  ) async {
    await _runRequest(() => _repository.setCartQuantity(productId, quantity));
    updateCartItemQuantity(productId, quantity);
    _error = null;
  }

  Future<void> removeFromCartWithPersistence(int userId, int productId) async {
    await _runRequest(() => _repository.setCartQuantity(productId, 0));
    removeFromCart(productId);
    _error = null;
  }

  Future<void> clearCartWithPersistence(int userId) async {
    await _runRequest(_repository.clearCart);
    clearCart();
    _error = null;
  }

  Future<bool> completeSale(
    int userId,
    String username, {
    String paymentMethod = 'QR',
  }) async {
    if (_cartItems.isEmpty) return false;
    try {
      final sale = await _repository.checkout(paymentMethod: paymentMethod);
      _sales = [sale, ..._sales.where((item) => item.id != sale.id)];
      _cartItems.clear();
      _error = null;
      notifyListeners();

      try {
        _products = await _repository.getProducts();
        _error = null;
      } catch (error) {
        _recordError(error);
      }
      return true;
    } catch (error) {
      _recordError(error);
      return false;
    }
  }

  Future<void> loadSales(int userId) async {
    await _runRequest(() async {
      _sales = await _repository.getSales();
    });
  }

  Future<List<Product>> getLowStockProducts(int userId) =>
      _runRequest(_repository.getLowStockProducts);

  Future<List<Sale>> getSalesByDateRange(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(() => _repository.getSalesByDateRange(startDate, endDate));

  Future<Map<String, dynamic>> getSalesByHour(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async => (await _repository.getSalesByHour(startDate, endDate)).toMap(),
  );

  Future<Map<String, dynamic>> getSalesByDay(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async => (await _repository.getSalesByDay(startDate, endDate)).toMap(),
  );

  Future<List<Map<String, dynamic>>> getTopSellingProducts(
    int userId,
    DateTime startDate,
    DateTime endDate, {
    int limit = 10,
  }) => _runRequest(
    () async => (await _repository.getTopSellingProducts(
      startDate,
      endDate,
      limit: limit,
    )).map((row) => row.toMap()).toList(),
  );

  Future<List<Map<String, dynamic>>> getCustomerPurchaseHistory(
    int userId, {
    int limit = 50,
  }) => _runRequest(
    () async => (await _repository.getCustomerPurchaseHistory(
      limit: limit,
    )).map((row) => row.toMap()).toList(),
  );

  Future<List<SaleItem>> getSaleItemsWithProducts(int saleId) =>
      _runRequest(() => _repository.getSaleItems(saleId));

  Future<bool> addInventoryRecord({
    required int userId,
    required int productId,
    required String changeType,
    required int stockBefore,
    required int stockAfter,
    String? notes,
  }) async {
    try {
      await _repository.adjustStock(
        productId,
        stockAfter,
        changeType: changeType,
        notes: notes,
      );
      final index = _products.indexWhere((product) => product.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(quantity: stockAfter);
      }
      _error = null;
      notifyListeners();
      return true;
    } catch (error) {
      _recordError(error);
      return false;
    }
  }

  Future<Map<String, dynamic>> getInventoryMovement(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async =>
        (await _repository.getInventoryMovement(startDate, endDate)).toMap(),
  );

  Future<List<Map<String, dynamic>>> getReorderSuggestions(int userId) =>
      _runRequest(
        () async => (await _repository.getReorderSuggestions())
            .map((row) => row.toMap())
            .toList(),
      );

  Future<Map<String, dynamic>> getSalesTrends(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async => (await _repository.getSalesTrends(startDate, endDate)).toMap(),
  );

  Future<List<Map<String, dynamic>>> getProductPerformance(
    int userId,
    DateTime startDate,
    DateTime endDate, {
    int limit = 20,
  }) => _runRequest(
    () async => (await _repository.getProductPerformance(
      startDate,
      endDate,
      limit: limit,
    )).map((row) => row.toMap()).toList(),
  );

  Future<Map<String, dynamic>> getCustomerSegmentation(
    int userId, {
    int limit = 100,
  }) => _runRequest(
    () async =>
        (await _repository.getCustomerSegmentation(limit: limit)).toMap(),
  );

  Future<Map<String, dynamic>> getDomesticExportSales(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async =>
        (await _repository.getDomesticExportSales(startDate, endDate)).toMap(),
  );

  Future<Map<String, dynamic>> getHistoricalProjectedRevenue(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async => (await _repository.getHistoricalProjectedRevenue(
      startDate,
      endDate,
    )).toMap(),
  );

  Future<List<Map<String, dynamic>>> getPaymentMethodDistribution(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async => (await _repository.getPaymentMethodDistribution(
      startDate,
      endDate,
    )).map((row) => row.toMap()).toList(),
  );

  Future<List<Map<String, dynamic>>> getCategoryPerformanceForRadar(
    int userId,
    DateTime startDate,
    DateTime endDate,
  ) => _runRequest(
    () async => (await _repository.getCategoryPerformance(
      startDate,
      endDate,
    )).map((row) => row.toMap()).toList(),
  );

  Future<DashboardReport> getDashboardReport() =>
      _runRequest(_repository.getDashboard);

  Future<double> getTodaySales(int userId) async =>
      (await getDashboardReport()).todayTotal;

  Future<int> getTodaySalesCount(int userId) async =>
      (await getDashboardReport()).todayCount;

  Future<T> _runRequest<T>(Future<T> Function() request) async {
    try {
      final result = await request();
      _error = null;
      return result;
    } catch (error) {
      _recordError(error);
      rethrow;
    }
  }

  void _recordError(Object error) {
    _error = error.toString();
    notifyListeners();
  }
}
