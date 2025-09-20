// FILE: lib/models/product.dart
class Product {
  final int? id;
  final int userId;
  final String name;
  final double price;
  final int quantity;
  final int lowStock;
  final String code;
  final String? category;
  final String unit;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.userId,
    required this.name,
    required this.price,
    required this.quantity,
    this.lowStock = 5,
    required this.code,
    this.category,
    this.unit = 'pcs',
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'low_stock': lowStock,
      'code': code,
      'category': category,
      'unit': unit,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      userId: map['user_id'],
      name: _safeStringFromMap(map, 'name') ?? '',
      price: map['price']?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      lowStock: map['low_stock'] ?? 5,
      code: _safeStringFromMap(map, 'code') ?? '',
      category: _safeStringFromMap(map, 'category'),
      unit: _safeStringFromMap(map, 'unit') ?? 'pcs',
      image: _safeStringFromMap(map, 'image'),
      createdAt: map['created_at'] != null ? DateTime.parse(_safeStringFromMap(map, 'created_at')!) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(_safeStringFromMap(map, 'updated_at')!) : null,
    );
  }
  
  /// Safely extract string from map, handling Blob types from MySQL
  static String? _safeStringFromMap(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    
    // Handle Blob type from MySQL
    if (value is List<int>) {
      return String.fromCharCodes(value);
    }
    
    // Handle regular string
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    
    // Convert other types to string
    return value.toString();
  }

  Product copyWith({
    int? id,
    int? userId,
    String? name,
    double? price,
    int? quantity,
    int? lowStock,
    String? code,
    String? category,
    String? unit,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      lowStock: lowStock ?? this.lowStock,
      code: code ?? this.code,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock => quantity <= lowStock;
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}