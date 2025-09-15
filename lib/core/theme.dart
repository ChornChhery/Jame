// FILE: lib/core/theme.dart
import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppConstants.primaryDarkBlue,
      colorScheme: ColorScheme.light(
        primary: AppConstants.primaryDarkBlue,
        secondary: AppConstants.primaryYellow,
        surface: AppConstants.primaryWhite,
        background: AppConstants.lightGray,
        error: AppConstants.errorRed,
        onPrimary: AppConstants.primaryWhite,
        onSecondary: AppConstants.textDarkGray,
        onSurface: AppConstants.textDarkGray,
        onBackground: AppConstants.textDarkGray,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.primaryDarkBlue,
        foregroundColor: AppConstants.primaryWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppConstants.primaryWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryDarkBlue,
          foregroundColor: AppConstants.primaryWhite,
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.softBlue,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.primaryWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppConstants.primaryDarkBlue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
cardTheme: CardThemeData(
  color: AppConstants.primaryWhite,
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppConstants.primaryWhite,
        selectedItemColor: AppConstants.primaryDarkBlue,
        unselectedItemColor: AppConstants.textDarkGray.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}