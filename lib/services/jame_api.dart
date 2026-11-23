import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';
import 'api_client.dart';

class JameApi {
  JameApi({ApiClient? client, bool? isWeb, FlutterSecureStorage? secureStorage})
    : _isWeb = isWeb ?? client?.isWeb ?? kIsWeb,
      _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      _client =
          client ??
          _createClient(
            isWeb ?? kIsWeb,
            secureStorage ?? const FlutterSecureStorage(),
          );

  static const String _accessTokenKey = 'jame_access_token';

  final bool _isWeb;
  final FlutterSecureStorage _secureStorage;
  final ApiClient _client;

  static ApiClient _createClient(
    bool isWeb,
    FlutterSecureStorage secureStorage,
  ) {
    return ApiClient(
      isWeb: isWeb,
      accessTokenProvider: isWeb
          ? null
          : () => secureStorage.read(key: _accessTokenKey),
    );
  }

  Future<User> login({required String email, required String password}) async {
    final response = await _client.postJson(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        'client_type': _isWeb ? 'web' : 'native',
      },
    );
    return _readAuthResponse(response);
  }

  Future<User> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    final response = await _client.postJson(
      '/auth/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'shop_name': shopName,
        'shop_address': shopAddress,
        'shop_phone': shopPhone,
        'client_type': _isWeb ? 'web' : 'native',
      },
    );
    return _readAuthResponse(response);
  }

  Future<User> restoreSession() async {
    try {
      final response = await _client.getJson('/auth/session');
      _client.setCsrfToken(response['csrf_token'] as String?);
      return User.fromMap(response['user'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearAccessToken();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _client.postJson('/auth/logout');
    } finally {
      _client.setCsrfToken(null);
      await _clearAccessToken();
    }
  }

  Future<User> updateProfile(User user) async {
    final response = await _client.patchJson(
      '/profile',
      body: {
        'first_name': user.firstName,
        'last_name': user.lastName,
        'shop_name': user.shopName,
        'shop_address': user.shopAddress,
        'shop_phone': user.shopPhone,
        'shop_email': user.shopEmail,
        'currency': user.currency,
        'payment_qr': user.paymentQr,
        'profile_image': user.profileImage,
      },
    );
    return User.fromMap(response);
  }

  Future<void> requestPasswordReset(String email) async {
    await _client.postJson(
      '/auth/password-reset/request',
      body: {'email': email},
    );
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.postJson(
      '/auth/password-reset/confirm',
      body: {'email': email, 'code': code, 'new_password': newPassword},
    );
  }

  Future<Map<String, dynamic>> checkReadiness() {
    return _client.getJson(_client.readinessUri.toString());
  }

  Future<User> _readAuthResponse(Map<String, dynamic> response) async {
    _client.setCsrfToken(response['csrf_token'] as String?);
    final token = response['access_token'] as String?;
    if (!_isWeb && (token == null || token.isEmpty)) {
      throw const ApiException(
        statusCode: 0,
        code: 'invalid_response',
        message: 'The server did not return an access token.',
      );
    }
    if (!_isWeb && token != null) {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    }
    return User.fromMap(response['user'] as Map<String, dynamic>);
  }

  Future<void> _clearAccessToken() async {
    if (!_isWeb) {
      await _secureStorage.delete(key: _accessTokenKey);
    }
  }
}
