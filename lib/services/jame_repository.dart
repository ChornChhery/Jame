import '../models/product.dart';
import '../models/report_models.dart';
import '../models/sale.dart';
import 'api_client.dart';
import 'jame_api.dart';

class JameRepository {
  JameRepository({required JameApi api}) : _api = api;

  final JameApi _api;

  Future<List<Product>> getProducts() async {
    final rows = await _api.getJsonList('/products');
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProductByCode(String code) async {
    try {
      return Product.fromMap(
        await _api.getJson('/products/by-code/${Uri.encodeComponent(code)}'),
      );
    } on ApiException catch (error) {
      if (error.code == 'product_not_found') return null;
      rethrow;
    }
  }

  Future<Product> createProduct(Product product) async {
    return Product.fromMap(
      await _api.postJson('/products', body: _productPayload(product)),
    );
  }

  Future<void> updateProduct(Product product) async {
    final productId = product.id;
    if (productId == null) {
      throw ArgumentError.value(productId, 'product.id', 'must not be null');
    }
    await _api.patchJson(
      '/products/$productId',
      body: _productPayload(product),
    );
  }

  Future<void> deleteProduct(int productId) =>
      _api.delete('/products/$productId');

  Future<void> adjustStock(
    int productId,
    int newQuantity, {
    required String changeType,
    String? notes,
  }) async {
    await _api.postJson(
      '/inventory/adjustments',
      body: {
        'product_id': productId,
        'new_quantity': newQuantity,
        'change_type': changeType,
        'notes': notes,
      },
    );
  }

  Future<List<CartItem>> getCart() async {
    final rows = await _api.getJsonList('/cart');
    return rows.map(_cartItemFromJson).toList();
  }

  Future<void> setCartQuantity(int productId, int quantity) async {
    if (quantity <= 0) {
      await _api.delete('/cart/items/$productId');
      return;
    }
    await _api.putJson('/cart/items/$productId', body: {'quantity': quantity});
  }

  Future<void> clearCart() => _api.delete('/cart');

  Future<Sale> checkout({required String paymentMethod}) async {
    final response = await _api.postJson(
      '/sales/checkout',
      body: {'payment_method': paymentMethod},
    );
    return Sale.fromMap(response);
  }

  Future<List<Sale>> getSales({DateTime? start, DateTime? end}) async {
    if ((start == null) != (end == null)) {
      throw ArgumentError('Both start and end are required for a sales range.');
    }
    final rows = start == null
        ? await _api.getJsonList('/sales')
        : await _api.getJsonList(
            '/reports/sales',
            queryParameters: _dateQuery(start, end!),
          );
    return rows.map(Sale.fromMap).toList();
  }

  Future<List<SaleItem>> getSaleItems(int saleId) async {
    final rows = await _api.getJsonList('/sales/$saleId/items');
    return rows.map(_saleItemFromJson).toList();
  }

  Future<DashboardReport> getDashboard() async {
    return DashboardReport.fromJson(await _api.getJson('/reports/dashboard'));
  }

  Future<List<Product>> getLowStockProducts() async {
    final rows = await _api.getJsonList('/inventory/low-stock');
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Sale>> getSalesByDateRange(DateTime start, DateTime end) async {
    return getSales(start: start, end: end);
  }

  Future<HourlySalesReport> getSalesByHour(DateTime start, DateTime end) async {
    return HourlySalesReport.fromJson(
      await _api.getJson(
        '/reports/sales/hourly',
        queryParameters: _dateQuery(start, end),
      ),
    );
  }

  Future<DailySalesReport> getSalesByDay(DateTime start, DateTime end) async {
    return DailySalesReport.fromJson(
      await _api.getJson(
        '/reports/sales/daily',
        queryParameters: _dateQuery(start, end),
      ),
    );
  }

  Future<List<TopProductRow>> getTopSellingProducts(
    DateTime start,
    DateTime end, {
    int limit = 10,
  }) async {
    final rows = await _api.getJsonList(
      '/reports/products/top',
      queryParameters: {..._dateQuery(start, end), 'limit': '$limit'},
    );
    return rows.map(TopProductRow.fromJson).toList();
  }

  Future<List<CustomerPurchaseRow>> getCustomerPurchaseHistory({
    int limit = 50,
  }) async {
    final rows = await _api.getJsonList(
      '/reports/customers/purchase-history',
      queryParameters: {'limit': '$limit'},
    );
    return rows.map(CustomerPurchaseRow.fromJson).toList();
  }

  Future<InventoryMovementReport> getInventoryMovement(
    DateTime start,
    DateTime end,
  ) async {
    return InventoryMovementReport.fromJson(
      await _api.getJson(
        '/reports/inventory/movement',
        queryParameters: _dateQuery(start, end),
      ),
    );
  }

  Future<List<ReorderSuggestion>> getReorderSuggestions() async {
    final rows = await _api.getJsonList(
      '/reports/inventory/reorder-suggestions',
    );
    return rows.map(ReorderSuggestion.fromJson).toList();
  }

  Future<SalesTrendsReport> getSalesTrends(DateTime start, DateTime end) async {
    return SalesTrendsReport.fromJson(
      await _api.getJson(
        '/reports/sales/trends',
        queryParameters: _dateQuery(start, end),
      ),
    );
  }

  Future<List<TopProductRow>> getProductPerformance(
    DateTime start,
    DateTime end, {
    int limit = 20,
  }) async {
    final rows = await _api.getJsonList(
      '/reports/products/performance',
      queryParameters: {..._dateQuery(start, end), 'limit': '$limit'},
    );
    return rows.map(TopProductRow.fromJson).toList();
  }

  Future<CustomerSegmentationReport> getCustomerSegmentation({
    int limit = 100,
  }) async {
    return CustomerSegmentationReport.fromJson(
      await _api.getJson(
        '/reports/customers/segmentation',
        queryParameters: {'limit': '$limit'},
      ),
    );
  }

  Future<DomesticExportReport> getDomesticExportSales(
    DateTime start,
    DateTime end,
  ) async {
    return DomesticExportReport.fromJson(
      await _api.getJson(
        '/reports/domestic-export-sales',
        queryParameters: _dateQuery(start, end),
      ),
    );
  }

  Future<RevenueProjectionReport> getHistoricalProjectedRevenue(
    DateTime start,
    DateTime end,
  ) async {
    return RevenueProjectionReport.fromJson(
      await _api.getJson(
        '/reports/revenue-projection',
        queryParameters: _dateQuery(start, end),
      ),
    );
  }

  Future<List<PaymentMethodRow>> getPaymentMethodDistribution(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _api.getJsonList(
      '/reports/payment-methods',
      queryParameters: _dateQuery(start, end),
    );
    return rows.map(PaymentMethodRow.fromJson).toList();
  }

  Future<List<CategoryPerformanceRow>> getCategoryPerformance(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _api.getJsonList(
      '/reports/categories',
      queryParameters: _dateQuery(start, end),
    );
    return rows.map(CategoryPerformanceRow.fromJson).toList();
  }

  Map<String, String> _dateQuery(DateTime start, DateTime end) => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };

  Map<String, dynamic> _productPayload(Product product) => {
    'name': product.name,
    'price': product.price,
    'quantity': product.quantity,
    'low_stock': product.lowStock,
    'code': product.code,
    'category': product.category,
    'unit': product.unit,
    'image': product.image,
  };

  CartItem _cartItemFromJson(Map<String, dynamic> json) {
    final product = Product.fromMap({
      'id': json['product_id'],
      'user_id': 0,
      'name': json['name'],
      'price': json['unit_price'],
      'quantity': json['available_quantity'],
      'low_stock': 0,
      'code': json['code'],
      'category': json['category'],
      'unit': json['unit'],
      'image': json['image'],
    });
    return CartItem(product: product, quantity: json['quantity'] as int);
  }

  SaleItem _saleItemFromJson(Map<String, dynamic> json) {
    final product = Product.fromMap({
      'id': json['product_id'],
      'user_id': 0,
      'name': json['product_name'],
      'price': json['unit_price'],
      'quantity': 0,
      'low_stock': 0,
      'code': json['product_code'],
      'category': json['category'],
      'unit': json['unit'],
      'image': json['image'],
    });
    return SaleItem.fromMap(json).copyWith(product: product);
  }
}
