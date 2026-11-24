// FILE: lib/core/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Jame';
  static const String appVersion = '1.0.0';
  static const String currency = 'USD';
  static const String currencySymbol = '\$';
  
  // Colors
  static const Color primaryYellow = Color(0xFFFFC928);
  static const Color primaryDarkBlue = Color(0xFF1E3A8A);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color successGreen = Color(0xFF90C659);
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color textDarkGray = Color(0xFF1F2937);
  static const Color errorRed = Color(0xFFDC2626);
  
  // Strings (English defaults)
  static const String loginTitle = 'Sign In';
  static const String signupTitle = 'Sign Up';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String shopName = 'Shop Name';
  static const String login = 'Sign In';
  static const String signup = 'Sign Up';
  static const String dashboard = 'Dashboard';
  static const String products = 'Products';
  static const String scanner = 'Scanner';
  static const String cart = 'Cart';
  static const String payment = 'Payment';
  static const String receipt = 'Receipt';
  static const String reports = 'Reports';
  static const String profile = 'Profile';
  
  // Routes
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String dashboardRoute = '/dashboard';
  static const String productsRoute = '/products';
  static const String scannerRoute = '/scanner';
  static const String cartRoute = '/cart';
  static const String paymentRoute = '/payment';
  static const String receiptRoute = '/receipt';
  static const String reportsRoute = '/reports';
  static const String profileRoute = '/profile';
  static const String paymentHistoryRoute = '/payment-history';
  
  // Database
  static const String dbName = 'jame.db';
  static const int dbVersion = 1;
  
  // Tables
  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String salesTable = 'sales';
  static const String saleItemsTable = 'sale_items';
  static const String inventoriesTable = 'inventories';
}
