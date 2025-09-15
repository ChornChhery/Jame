// FILE: lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../database/database_helper.dart';
import '../core/utils.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final hashedPassword = AppUtils.hashPassword(password);
      final user = await DatabaseHelper.instance.getUserByEmail(email);

      if (user != null && user.password == hashedPassword) {
        _currentUser = user;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
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
    notifyListeners();

    try {
      // Check if user already exists
      final existingUserByEmail = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUserByEmail != null) {
        _isLoading = false;
        notifyListeners();
        return 'อีเมลนี้ถูกใช้แล้ว';
      }

      final existingUserByUsername = await DatabaseHelper.instance.getUserByUsername(username);
      if (existingUserByUsername != null) {
        _isLoading = false;
        notifyListeners();
        return 'ชื่อผู้ใช้นี้ถูกใช้แล้ว';
      }

      // Create new user
      final hashedPassword = AppUtils.hashPassword(password);
      final newUser = User(
        username: username,
        email: email,
        password: hashedPassword,
        firstName: firstName,
        lastName: lastName,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        currency: 'THB',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdUser = await DatabaseHelper.instance.createUser(newUser);
      _currentUser = createdUser;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'เกิดข้อผิดพลาด: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}