// FILE: lib/models/user.dart
class User {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String? shopEmail;
  final String currency;
  final String? paymentQr;
  final String? profileImage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.shopEmail,
    this.currency = 'THB',
    this.paymentQr,
    this.profileImage,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_phone': shopPhone,
      'shop_email': shopEmail,
      'currency': currency,
      'payment_qr': paymentQr,
      'profile_image': profileImage,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: _safeStringFromMap(map, 'username') ?? '',
      email: _safeStringFromMap(map, 'email') ?? '',
      password: _safeStringFromMap(map, 'password') ?? '',
      firstName: _safeStringFromMap(map, 'first_name') ?? '',
      lastName: _safeStringFromMap(map, 'last_name') ?? '',
      shopName: _safeStringFromMap(map, 'shop_name') ?? '',
      shopAddress: _safeStringFromMap(map, 'shop_address'),
      shopPhone: _safeStringFromMap(map, 'shop_phone'),
      shopEmail: _safeStringFromMap(map, 'shop_email'),
      currency: _safeStringFromMap(map, 'currency') ?? 'THB',
      paymentQr: _safeStringFromMap(map, 'payment_qr'),
      profileImage: _safeStringFromMap(map, 'profile_image'),
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

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? shopEmail,
    String? currency,
    String? paymentQr,
    String? profileImage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      shopEmail: shopEmail ?? this.shopEmail,
      currency: currency ?? this.currency,
      paymentQr: paymentQr ?? this.paymentQr,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullName => '$firstName $lastName';
}