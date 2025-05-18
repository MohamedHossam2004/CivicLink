// lib/config/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF8B5CF6); // violet-500
  static const Color primaryDarkColor = Color(0xFF7C3AED); // violet-600
  static const Color primaryLightColor = Color(0xFFEDE9FE); // violet-100

  // Secondary colors
  static const Color secondaryColor = Color(0xFF4F46E5); // indigo-600
  static const Color secondaryLightColor = Color(0xFFE0E7FF); // indigo-100

  // Background colors
  static const Color backgroundColor = Color(0xFFF8FAFC); // slate-50
  static const Color cardColor = Colors.white;

  // Text colors
  static const Color textPrimaryColor = Color(0xFF1E293B); // slate-800
  static const Color textSecondaryColor = Color(0xFF64748B); // slate-500

  // Category colors
  static const Color environmentColor = Color(0xFF10B981); // green-500
  static const Color communityColor = Color(0xFFF59E0B); // amber-500
  static const Color healthcareColor = Color(0xFF3B82F6); // blue-500
  static const Color educationColor = Color(0xFF6366F1); // indigo-500

  static ThemeData lightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: const BorderSide(color: Color(0xFFE2E8F0)), // slate-200
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // slate-100
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: primaryColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: Colors.red,
        surface: cardColor,
      ),
    );
  }
}
