// FILE: lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../database/database_helper.dart';
import '../core/utils.dart';
import '../core/connectdb.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _rememberMe = false;
  final ConnectDB _connectDB = ConnectDB(); // Add server connection

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  
  set rememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  AuthProvider() {
    _loadSavedSession();
  }

  /// Load saved session from SharedPreferences
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _rememberMe = prefs.getBool('remember_me') ?? false;
      
      if (_rememberMe) {
        final userId = prefs.getInt('user_id');
        if (userId != null) {
          final user = await DatabaseHelper.instance.getUser(userId);
          if (user != null) {
            _currentUser = user;
            _isAuthenticated = true;
            debugPrint('✅ Restored user session for: ${user.username}');
          }
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading saved session: $e');
    }
  }

  /// Save session to SharedPreferences
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe && _currentUser != null) {
        await prefs.setBool('remember_me', true);
        await prefs.setInt('user_id', _currentUser!.id!);
      } else {
        await prefs.setBool('remember_me', false);
        await prefs.remove('user_id');
      }
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
    }
  }

  /// Clear saved session
  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', false);
      await prefs.remove('user_id');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _isLoading = true;
    _rememberMe = rememberMe;
    notifyListeners();

    try {
      // Direct MySQL authentication - no local fallback
      final hashedPassword = AppUtils.hashPassword(password);
      final user = await DatabaseHelper.instance.getUserByEmail(email);

      if (user != null && user.password == hashedPassword) {
        _currentUser = user;
        _isAuthenticated = true;
        
        // Save session if "Remember Me" is enabled
        if (rememberMe) {
          await _saveSession();
        }
        
        debugPrint('✅ User login successful: ${user.username}');
        
        _isLoading = false;
        notifyListeners();
        return true;
      }

      debugPrint('❌ Login failed: Invalid credentials for $email');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Login error: $e');
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
      // Check if user already exists in MySQL
      final existingUserByEmail = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUserByEmail != null) {
        _isLoading = false;
        notifyListeners();
        return 'อีเมลนี้ถูกใช้แล้ว'; // Email already used
      }

      final existingUserByUsername = await DatabaseHelper.instance.getUserByUsername(username);
      if (existingUserByUsername != null) {
        _isLoading = false;
        notifyListeners();
        return 'ชื่อผู้ใช้นี้ถูกใช้แล้ว'; // Username already used
      }

      // Create new user directly in MySQL
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
        currency: 'THB', // Thai market focus
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdUser = await DatabaseHelper.instance.createUser(newUser);
      _currentUser = createdUser;
      _isAuthenticated = true;
      
      debugPrint('✅ User registration successful: ${createdUser.username}');
      
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return 'เกิดข้อผิดพลาด: ${e.toString()}';
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;
    _rememberMe = false;
    await _clearSession();
    notifyListeners();
  }

  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.updateUser(updatedUser);
      _currentUser = updatedUser;
      await _saveSession(); // Save updated user info
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== MYSQL CONNECTION TESTING ====================
  
  /// Test MySQL connection for debugging (non-blocking with caching)
  bool? _lastConnectionStatus;
  DateTime? _lastConnectionTest;
  
  Future<bool> testServerConnection() async {
    try {
      // Cache connection status for 30 seconds to avoid blocking UI
      final now = DateTime.now();
      if (_lastConnectionTest != null && 
          _lastConnectionStatus != null &&
          now.difference(_lastConnectionTest!).inSeconds < 30) {
        return _lastConnectionStatus!;
      }
      
      // Test with reduced retries for faster response
      final result = await _connectDB.testMySQLConnection(maxRetries: 1);
      
      _lastConnectionStatus = result;
      _lastConnectionTest = now;
      
      debugPrint(result ? '✅ MySQL connection test: SUCCESS' : '❌ MySQL connection test: FAILED');
      return result;
    } catch (e) {
      debugPrint('❌ MySQL connection test error: $e');
      _lastConnectionStatus = false;
      _lastConnectionTest = DateTime.now();
      return false;
    }
  }
  
  /// Background connection test (fire and forget)
  void testServerConnectionBackground() {
    // Run in background without blocking UI
    testServerConnection().catchError((e) {
      debugPrint('Background connection test failed: $e');
    });
  }
  
  /// Get MySQL server status for debugging
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      return await _connectDB.getServerStatus();
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}