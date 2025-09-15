// FILE: lib/providers/settings_provider.dart
import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'th';
  bool _showLowStockAlerts = true;
  bool _autoBackup = false;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get showLowStockAlerts => _showLowStockAlerts;
  bool get autoBackup => _autoBackup;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }

  void toggleLowStockAlerts() {
    _showLowStockAlerts = !_showLowStockAlerts;
    notifyListeners();
  }

  void toggleAutoBackup() {
    _autoBackup = !_autoBackup;
    notifyListeners();
  }
}