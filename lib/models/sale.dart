// FILE: lib/models/sale.dart
import 'product.dart';
class Sale {
  final int? id;
  final int userId;
  final DateTime saleDate;
  final double totalAmount;
  final String paymentStatus;
  final String receiptNumber;
  final String paymentMethod;
  final String? description;
  final String? customerName;
  final String? customerPhone;
  final List<SaleItem>? items;

  Sale({
    this.id,
    required this.userId,
    required this.saleDate,
    required this.totalAmount,
    this.paymentStatus = 'Completed',
    required this.receiptNumber,
    this.paymentMethod = 'QR',
    this.description,
    this.customerName,
    this.customerPhone,
    this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'sale_date': saleDate.toIso8601String(),
      'total_amount': totalAmount,
      'payment_status': paymentStatus,
      'receipt_number': receiptNumber,
      'payment_method': paymentMethod,
      'description': description,
      'customer_name': customerName,
      'customer_phone': customerPhone,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      userId: map['user_id'],
      saleDate: DateTime.parse(map['sale_date']),
      totalAmount: map['total_amount']?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status'] ?? 'Completed',
      receiptNumber: map['receipt_number'],
      paymentMethod: map['payment_method'] ?? 'QR',
      description: map['description'],
      customerName: map['customer_name'],
      customerPhone: map['customer_phone'],
    );
  }

  Sale copyWith({
    int? id,
    int? userId,
    DateTime? saleDate,
    double? totalAmount,
    String? paymentStatus,
    String? receiptNumber,
    String? paymentMethod,
    String? description,
    String? customerName,
    String? customerPhone,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      saleDate: saleDate ?? this.saleDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
    );
  }
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Product? product;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.product,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      unitPrice: map['unit_price']?.toDouble() ?? 0.0,
      totalPrice: map['total_price']?.toDouble() ?? 0.0,
    );
  }

  factory SaleItem.fromCartItem(CartItem cartItem, int saleId) {
    return SaleItem(
      saleId: saleId,
      productId: cartItem.product.id!,
      quantity: cartItem.quantity,
      unitPrice: cartItem.product.price,
      totalPrice: cartItem.totalPrice,
    );
  }

    SaleItem copyWith({
      int? id,
      int? saleId,
      int? productId,
      int? quantity,
      double? unitPrice,
      double? totalPrice,
      Product? product,
    }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      product: product ?? this.product,
    );
  }

}