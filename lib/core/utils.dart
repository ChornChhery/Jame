// FILE: lib/core/utils.dart
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'constants.dart';

class AppUtils {
  // Currency formatting for Thai Baht
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '${AppConstants.currencySymbol}${formatter.format(amount)}';
  }
  
  // Date formatting
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
  
  // Password hashing
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Generate receipt number
  static String generateReceiptNumber(String username) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final timeStr = DateFormat('HHmmss').format(now);
    return '${username.toUpperCase()}-$dateStr-$timeStr';
  }
  
  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Validate password
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  // Format phone number for PromptPay
  static String formatPromptPayPhone(String phone) {
    // Remove all non-digits
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Add country code if not present
    if (cleaned.startsWith('0')) {
      cleaned = '66' + cleaned.substring(1);
    } else if (!cleaned.startsWith('66')) {
      cleaned = '66' + cleaned;
    }
    
    return cleaned;
  }
}