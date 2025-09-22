// FILE: lib/core/utils.dart
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AppUtils {
  // Email validation regex
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Password validation (at least 6 characters)
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Format currency with Thai Baht symbol
  static String formatCurrency(double amount) {
    final format = NumberFormat("#,##0.00", "th_TH");
    return '฿${format.format(amount)}';
  }

  // Format datetime for Thai display
  static String formatDateTimeThai(DateTime dateTime) {
    final format = DateFormat('dd/MM/yyyy HH:mm', 'th_TH');
    return format.format(toThaiTime(dateTime));
  }

  // Format date only for Thai display
  static String formatDateThai(DateTime dateTime) {
    final format = DateFormat('dd/MM/yyyy', 'th_TH');
    return format.format(toThaiTime(dateTime));
  }

  // Convert UTC time to Thailand time (UTC+7)
  static DateTime toThaiTime(DateTime dateTime) {
    // Thailand is UTC+7
    return dateTime.toUtc().add(const Duration(hours: 7));
  }

  // Convert Thailand time to UTC (for database storage)
  static DateTime toUtcTime(DateTime dateTime) {
    // If the dateTime is already in Thailand time, convert to UTC
    return dateTime.isUtc ? dateTime : dateTime.subtract(const Duration(hours: 7));
  }

  // Generate receipt number with Thai timezone consideration
  static String generateReceiptNumber(String username) {
    final now = toThaiTime(DateTime.now());
    final datePart = DateFormat('yyyyMMddHHmmss').format(now);
    final randomPart = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'RCT${datePart}${randomPart}';
  }

  // Validate if a string is a valid phone number
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^[0-9]{9,10}$');
    return phoneRegex.hasMatch(phone);
  }

  // Validate if a string is a valid Thai ID (13 digits)
  static bool isValidThaiID(String id) {
    if (id.length != 13) return false;
    final idRegex = RegExp(r'^[0-9]{13}$');
    return idRegex.hasMatch(id);
  }

  // Hash password using SHA256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}