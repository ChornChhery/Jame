// FILE: lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import '../core/translations.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'en'; // Default to English
  bool _showLowStockAlerts = true;
  bool _autoBackup = false;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get isKhmer => _language == 'km';
  bool get isEnglish => _language == 'en';
  bool get showLowStockAlerts => _showLowStockAlerts;
  bool get autoBackup => _autoBackup;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String language) {
    if (_language != language) {
      _language = (language == 'km') ? 'km' : 'en';
      notifyListeners();
    }
  }

  void toggleLanguage() {
    _language = (_language == 'en') ? 'km' : 'en';
    notifyListeners();
  }

  String tr(String key) {
    return AppTranslations.get(key, _language);
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
