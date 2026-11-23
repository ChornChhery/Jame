import 'product.dart';
import 'sale.dart';

double _asDouble(Object? value, String field) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected numeric report field "$field".');
}

int _asInt(Object? value, String field) {
  if (value is num) return value.toInt();
  if (value is String) return int.parse(value);
  throw FormatException('Expected integer report field "$field".');
}

String _asString(Object? value, String field) {
  if (value is String) return value;
  throw FormatException('Expected string report field "$field".');
}

DateTime _asDate(Object? value, String field) {
  return DateTime.parse(_asString(value, field));
}

String? _asNullableString(Object? value, String field) {
  if (value == null || value is String) return value as String?;
  throw FormatException('Expected string report field "$field".');
}

class HourlySalesRow {
  const HourlySalesRow({
    required this.hour,
    required this.transactionCount,
    required this.totalRevenue,
  });

  final int hour;
  final int transactionCount;
  final double totalRevenue;

  factory HourlySalesRow.fromJson(Map<String, dynamic> json) => HourlySalesRow(
    hour: _asInt(json['hour'], 'hour'),
    transactionCount: _asInt(json['transaction_count'], 'transaction_count'),
    totalRevenue: _asDouble(json['total_revenue'], 'total_revenue'),
  );

  Map<String, dynamic> toMap() => {
    'hour': hour,
    'transaction_count': transactionCount,
    'total_revenue': totalRevenue,
  };
}

class DailySalesRow {
  const DailySalesRow({
    required this.saleDay,
    required this.transactionCount,
    required this.totalRevenue,
  });

  final DateTime saleDay;
  final int transactionCount;
  final double totalRevenue;

  factory DailySalesRow.fromJson(Map<String, dynamic> json) => DailySalesRow(
    saleDay: _asDate(json['sale_day'], 'sale_day'),
    transactionCount: _asInt(json['transaction_count'], 'transaction_count'),
    totalRevenue: _asDouble(json['total_revenue'], 'total_revenue'),
  );

  Map<String, dynamic> toMap() => {
    'sale_day': saleDay.toIso8601String(),
    'transaction_count': transactionCount,
    'total_revenue': totalRevenue,
  };
}

class TopProductRow {
  const TopProductRow({
    required this.name,
    required this.code,
    required this.image,
    required this.totalQuantity,
    required this.totalRevenue,
    required this.saleCount,
  });

  final String name;
  final String code;
  final String? image;
  final int totalQuantity;
  final double totalRevenue;
  final int saleCount;

  factory TopProductRow.fromJson(Map<String, dynamic> json) => TopProductRow(
    name: _asString(json['name'], 'name'),
    code: _asString(json['code'], 'code'),
    image: _asNullableString(json['image'], 'image'),
    totalQuantity: _asInt(json['total_quantity'], 'total_quantity'),
    totalRevenue: _asDouble(json['total_revenue'], 'total_revenue'),
    saleCount: _asInt(json['sale_count'], 'sale_count'),
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'image': image,
    'total_quantity': totalQuantity,
    'total_revenue': totalRevenue,
    'sale_count': saleCount,
  };
}

class CustomerPurchaseRow {
  const CustomerPurchaseRow({
    required this.customerName,
    required this.customerPhone,
    required this.purchaseCount,
    required this.totalSpent,
    required this.lastPurchaseDate,
  });

  final String customerName;
  final String? customerPhone;
  final int purchaseCount;
  final double totalSpent;
  final DateTime lastPurchaseDate;

  factory CustomerPurchaseRow.fromJson(
    Map<String, dynamic> json,
  ) => CustomerPurchaseRow(
    customerName: _asString(json['customer_name'], 'customer_name'),
    customerPhone: _asNullableString(json['customer_phone'], 'customer_phone'),
    purchaseCount: _asInt(json['purchase_count'], 'purchase_count'),
    totalSpent: _asDouble(json['total_spent'], 'total_spent'),
    lastPurchaseDate: _asDate(json['last_purchase_date'], 'last_purchase_date'),
  );

  Map<String, dynamic> toMap() => {
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'purchase_count': purchaseCount,
    'total_spent': totalSpent,
    'last_purchase_date': lastPurchaseDate.toIso8601String(),
  };
}

class InventoryMovementRow {
  const InventoryMovementRow({
    required this.name,
    required this.code,
    required this.soldQuantity,
    required this.receivedQuantity,
    required this.lastUpdated,
  });

  final String name;
  final String code;
  final int soldQuantity;
  final int receivedQuantity;
  final DateTime lastUpdated;

  factory InventoryMovementRow.fromJson(Map<String, dynamic> json) =>
      InventoryMovementRow(
        name: _asString(json['name'], 'name'),
        code: _asString(json['code'], 'code'),
        soldQuantity: _asInt(json['sold_quantity'], 'sold_quantity'),
        receivedQuantity: _asInt(
          json['received_quantity'],
          'received_quantity',
        ),
        lastUpdated: _asDate(json['last_updated'], 'last_updated'),
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'sold_quantity': soldQuantity,
    'received_quantity': receivedQuantity,
    'last_updated': lastUpdated.toIso8601String(),
  };
}

class ReorderSuggestion {
  const ReorderSuggestion({
    required this.name,
    required this.code,
    required this.image,
    required this.quantity,
    required this.lowStock,
    required this.unit,
    required this.averageDailySales,
    required this.daysUntilOutOfStock,
  });

  final String name;
  final String code;
  final String? image;
  final int quantity;
  final int lowStock;
  final String unit;
  final double averageDailySales;
  final double daysUntilOutOfStock;

  factory ReorderSuggestion.fromJson(Map<String, dynamic> json) =>
      ReorderSuggestion(
        name: _asString(json['name'], 'name'),
        code: _asString(json['code'], 'code'),
        image: _asNullableString(json['image'], 'image'),
        quantity: _asInt(json['quantity'], 'quantity'),
        lowStock: _asInt(json['low_stock'], 'low_stock'),
        unit: _asString(json['unit'], 'unit'),
        averageDailySales: _asDouble(
          json['avg_daily_sales'],
          'avg_daily_sales',
        ),
        daysUntilOutOfStock: _asDouble(
          json['days_until_out_of_stock'],
          'days_until_out_of_stock',
        ),
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'image': image,
    'quantity': quantity,
    'low_stock': lowStock,
    'unit': unit,
    'avg_daily_sales': averageDailySales,
    'days_until_out_of_stock': daysUntilOutOfStock,
  };
}

class PaymentMethodRow {
  const PaymentMethodRow({
    required this.paymentMethod,
    required this.transactionCount,
    required this.totalRevenue,
  });

  final String paymentMethod;
  final int transactionCount;
  final double totalRevenue;

  factory PaymentMethodRow.fromJson(Map<String, dynamic> json) =>
      PaymentMethodRow(
        paymentMethod: _asString(json['payment_method'], 'payment_method'),
        transactionCount: _asInt(
          json['transaction_count'],
          'transaction_count',
        ),
        totalRevenue: _asDouble(json['total_revenue'], 'total_revenue'),
      );

  Map<String, dynamic> toMap() => {
    'payment_method': paymentMethod,
    'transaction_count': transactionCount,
    'total_revenue': totalRevenue,
  };
}

class CategoryPerformanceRow {
  const CategoryPerformanceRow({
    required this.category,
    required this.totalRevenue,
    required this.totalQuantity,
    required this.transactionCount,
  });

  final String category;
  final double totalRevenue;
  final int totalQuantity;
  final int transactionCount;

  factory CategoryPerformanceRow.fromJson(Map<String, dynamic> json) =>
      CategoryPerformanceRow(
        category: _asString(json['category'], 'category'),
        totalRevenue: _asDouble(json['total_revenue'], 'total_revenue'),
        totalQuantity: _asInt(json['total_quantity'], 'total_quantity'),
        transactionCount: _asInt(
          json['transaction_count'],
          'transaction_count',
        ),
      );

  Map<String, dynamic> toMap() => {
    'category': category,
    'total_revenue': totalRevenue,
    'total_quantity': totalQuantity,
    'transaction_count': transactionCount,
  };
}

class DomesticExportRow {
  const DomesticExportRow({
    required this.saleDay,
    required this.domesticRevenue,
    required this.exportRevenue,
    required this.domesticCount,
    required this.exportCount,
  });

  final DateTime saleDay;
  final double domesticRevenue;
  final double exportRevenue;
  final int domesticCount;
  final int exportCount;

  factory DomesticExportRow.fromJson(Map<String, dynamic> json) =>
      DomesticExportRow(
        saleDay: _asDate(json['sale_day'], 'sale_day'),
        domesticRevenue: _asDouble(
          json['domestic_revenue'],
          'domestic_revenue',
        ),
        exportRevenue: _asDouble(json['export_revenue'], 'export_revenue'),
        domesticCount: _asInt(json['domestic_count'], 'domestic_count'),
        exportCount: _asInt(json['export_count'], 'export_count'),
      );

  Map<String, dynamic> toMap() => {
    'sale_day': saleDay.toIso8601String(),
    'domestic_revenue': domesticRevenue,
    'export_revenue': exportRevenue,
    'domestic_count': domesticCount,
    'export_count': exportCount,
  };
}

class RevenueHistoryRow {
  const RevenueHistoryRow({required this.period, required this.actualRevenue});

  final DateTime period;
  final double actualRevenue;

  factory RevenueHistoryRow.fromJson(Map<String, dynamic> json) =>
      RevenueHistoryRow(
        period: _asDate(json['period'], 'period'),
        actualRevenue: _asDouble(json['actual_revenue'], 'actual_revenue'),
      );

  Map<String, dynamic> toMap() => {
    'period': period.toIso8601String(),
    'actual_revenue': actualRevenue,
  };
}

class DashboardReport {
  const DashboardReport({
    required this.todayTotal,
    required this.todayCount,
    required this.sales,
    required this.topProducts,
    required this.lowStock,
  });

  final double todayTotal;
  final int todayCount;
  final List<Sale> sales;
  final List<TopProductRow> topProducts;
  final List<Product> lowStock;

  factory DashboardReport.fromJson(Map<String, dynamic> json) =>
      DashboardReport(
        todayTotal: _asDouble(json['today_total'], 'today_total'),
        todayCount: _asInt(json['today_count'], 'today_count'),
        sales: (json['sales'] as List)
            .map((item) => Sale.fromMap(item as Map<String, dynamic>))
            .toList(),
        topProducts: (json['top_products'] as List)
            .map((item) => TopProductRow.fromJson(item as Map<String, dynamic>))
            .toList(),
        lowStock: (json['low_stock'] as List)
            .map((item) => Product.fromMap(item as Map<String, dynamic>))
            .toList(),
      );
}

class HourlySalesReport {
  const HourlySalesReport(this.rows);

  final List<HourlySalesRow> rows;

  factory HourlySalesReport.fromJson(Map<String, dynamic> json) =>
      HourlySalesReport(
        (json['hourlyData'] as List)
            .map(
              (item) => HourlySalesRow.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  Map<String, dynamic> toMap() => {
    'hourlyData': rows.map((row) => row.toMap()).toList(),
  };
}

class DailySalesReport {
  const DailySalesReport(this.rows);

  final List<DailySalesRow> rows;

  factory DailySalesReport.fromJson(Map<String, dynamic> json) =>
      DailySalesReport(
        (json['dailyData'] as List)
            .map((item) => DailySalesRow.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
    'dailyData': rows.map((row) => row.toMap()).toList(),
  };
}

class InventoryMovementReport {
  const InventoryMovementReport(this.rows);

  final List<InventoryMovementRow> rows;

  factory InventoryMovementReport.fromJson(Map<String, dynamic> json) =>
      InventoryMovementReport(
        (json['inventoryData'] as List)
            .map(
              (item) =>
                  InventoryMovementRow.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  Map<String, dynamic> toMap() => {
    'inventoryData': rows.map((row) => row.toMap()).toList(),
  };
}

class SalesTrendsReport {
  const SalesTrendsReport({
    required this.currentPeriodData,
    required this.previousPeriodData,
    required this.currentRevenue,
    required this.previousRevenue,
    required this.growthRate,
  });

  final DailySalesReport currentPeriodData;
  final DailySalesReport previousPeriodData;
  final double currentRevenue;
  final double previousRevenue;
  final double growthRate;

  factory SalesTrendsReport.fromJson(Map<String, dynamic> json) =>
      SalesTrendsReport(
        currentPeriodData: DailySalesReport.fromJson(
          json['currentPeriodData'] as Map<String, dynamic>,
        ),
        previousPeriodData: DailySalesReport.fromJson(
          json['previousPeriodData'] as Map<String, dynamic>,
        ),
        currentRevenue: _asDouble(json['currentRevenue'], 'currentRevenue'),
        previousRevenue: _asDouble(json['previousRevenue'], 'previousRevenue'),
        growthRate: _asDouble(json['growthRate'], 'growthRate'),
      );

  Map<String, dynamic> toMap() => {
    'currentPeriodData': currentPeriodData.toMap(),
    'previousPeriodData': previousPeriodData.toMap(),
    'currentRevenue': currentRevenue,
    'previousRevenue': previousRevenue,
    'growthRate': growthRate,
  };
}

class CustomerSegmentationReport {
  const CustomerSegmentationReport({
    required this.segments,
    required this.totalCustomers,
    required this.averageSpentPerCustomer,
    required this.totalRevenue,
  });

  final Map<String, int> segments;
  final int totalCustomers;
  final double averageSpentPerCustomer;
  final double totalRevenue;

  factory CustomerSegmentationReport.fromJson(Map<String, dynamic> json) =>
      CustomerSegmentationReport(
        segments: (json['segments'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, _asInt(value, 'segments.$key')),
        ),
        totalCustomers: _asInt(json['totalCustomers'], 'totalCustomers'),
        averageSpentPerCustomer: _asDouble(
          json['averageSpentPerCustomer'],
          'averageSpentPerCustomer',
        ),
        totalRevenue: _asDouble(json['totalRevenue'], 'totalRevenue'),
      );

  Map<String, dynamic> toMap() => {
    'segments': segments,
    'totalCustomers': totalCustomers,
    'averageSpentPerCustomer': averageSpentPerCustomer,
    'totalRevenue': totalRevenue,
  };
}

class DomesticExportReport {
  const DomesticExportReport(this.rows);

  final List<DomesticExportRow> rows;

  factory DomesticExportReport.fromJson(Map<String, dynamic> json) =>
      DomesticExportReport(
        (json['dailyData'] as List)
            .map(
              (item) =>
                  DomesticExportRow.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  Map<String, dynamic> toMap() => {
    'dailyData': rows.map((row) => row.toMap()).toList(),
  };
}

class RevenueProjectionReport {
  const RevenueProjectionReport({
    required this.historicalData,
    required this.projectionAverage,
  });

  final List<RevenueHistoryRow> historicalData;
  final double projectionAverage;

  factory RevenueProjectionReport.fromJson(Map<String, dynamic> json) =>
      RevenueProjectionReport(
        historicalData: (json['historicalData'] as List)
            .map(
              (item) =>
                  RevenueHistoryRow.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        projectionAverage: _asDouble(
          json['projectionAverage'],
          'projectionAverage',
        ),
      );

  Map<String, dynamic> toMap() => {
    'historicalData': historicalData.map((row) => row.toMap()).toList(),
    'projectionAverage': projectionAverage,
  };
}
