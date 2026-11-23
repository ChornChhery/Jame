import 'dart:async';

import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/jame_api.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({JameApi? api}) : _api = api ?? JameApi() {
    initialization = restoreSession();
  }

  final JameApi _api;
  late final Future<void> initialization;
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  String? _error;
  bool? _lastConnectionStatus;
  DateTime? _lastConnectionTest;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  String? get error => _error;

  set rememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _api.restoreSession();
      _isAuthenticated = true;
      _error = null;
    } on ApiException catch (error) {
      _currentUser = null;
      _isAuthenticated = false;
      _error = error.statusCode == 401 ? null : error.message;
    } on Exception catch (error) {
      _currentUser = null;
      _isAuthenticated = false;
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _rememberMe = rememberMe;
    _error = null;
    notifyListeners();
    try {
      final normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail.endsWith('@gmail.com')) {
        _error = 'Only Gmail accounts are allowed.';
        return false;
      }
      _currentUser = await _api.login(
        email: normalizedEmail,
        password: password,
      );
      _isAuthenticated = true;
      return true;
    } on Exception catch (error) {
      _error = _errorMessage(error);
      _currentUser = null;
      _isAuthenticated = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signup({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String shopName,
    String? shopAddress,
    String? shopPhone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUser = await _api.register(
        username: username,
        email: email.trim().toLowerCase(),
        password: password,
        firstName: firstName,
        lastName: lastName,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
      );
      _isAuthenticated = true;
      return null;
    } on Exception catch (error) {
      _error = _errorMessage(error);
      _currentUser = null;
      _isAuthenticated = false;
      return _error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _api.logout();
      _error = null;
    } on Exception catch (error) {
      _error = _errorMessage(error);
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _rememberMe = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUser = await _api.updateProfile(updatedUser);
      return true;
    } on Exception catch (error) {
      _error = _errorMessage(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _api.requestPasswordReset(email);
      _error = null;
    } on Exception catch (error) {
      _error = _errorMessage(error);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await _api.confirmPasswordReset(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      _error = null;
    } on Exception catch (error) {
      _error = _errorMessage(error);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> testServerConnection() async {
    final now = DateTime.now();
    if (_lastConnectionTest != null &&
        _lastConnectionStatus != null &&
        now.difference(_lastConnectionTest!).inSeconds < 30) {
      return _lastConnectionStatus!;
    }
    try {
      await _api.checkReadiness();
      _lastConnectionStatus = true;
      _error = null;
    } on Exception catch (error) {
      _lastConnectionStatus = false;
      _error = _errorMessage(error);
    }
    _lastConnectionTest = now;
    notifyListeners();
    return _lastConnectionStatus!;
  }

  void testServerConnectionBackground() {
    unawaited(testServerConnection());
  }

  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      return await _api.checkReadiness();
    } on Exception catch (error) {
      return {'error': _errorMessage(error)};
    }
  }

  String _errorMessage(Exception error) {
    return error is ApiException ? error.message : error.toString();
  }
}
