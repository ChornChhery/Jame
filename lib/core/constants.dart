// FILE: lib/core/constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'Jame';
  static const String appVersion = '1.0.0';
  static const String currency = 'THB';
  static const String currencySymbol = '฿';
  
  // Colors - Thai Market Theme
  static const Color primaryYellow = Color(0xFFFFC928);
  static const Color primaryDarkBlue = Color(0xFF1E3A8A);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color accentOrange = Color(0xFFFFA500);
  static const Color successGreen = Color(0xFF90C659);
  static const Color softBlue = Color(0xFF3B82F6);
  static const Color textDarkGray = Color(0xFF1F2937);
  static const Color errorRed = Color(0xFFDC2626);
  
  // Strings
  static const String loginTitle = 'เข้าสู่ระบบ';
  static const String signupTitle = 'สมัครสมาชิก';
  static const String email = 'อีเมล';
  static const String password = 'รหัสผ่าน';
  static const String shopName = 'ชื่อร้าน';
  static const String login = 'เข้าสู่ระบบ';
  static const String signup = 'สมัครสมาชิก';
  static const String dashboard = 'หน้าหลัก';
  static const String products = 'สินค้า';
  static const String scanner = 'สแกน';
  static const String cart = 'ตะกร้า';
  static const String payment = 'ชำระเงิน';
  static const String receipt = 'ใบเสร็จ';
  static const String reports = 'รายงาน';
  static const String profile = 'โปรไฟล์';
  
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
