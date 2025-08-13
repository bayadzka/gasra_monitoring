import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Warna utama CNG
  static const Color primary = Color(0xFF005DAA); // Biru Tua
  static const Color secondary = Color(0xFF49B5E7); // Biru Muda
  static const Color background = Color(0xFFF2F2F2); // Abu Muda
  static const Color surface = Color(0xFFFFFFFF); // Putih
  static const Color textPrimary = Color(0xFF1A1A1A); // Abu Tua
  static const Color textSecondary = Color(0xFF555555); // Abu Sedang
  static const Color success = Color(0xFF25D366); // Hijau WA
  static const Color error = Colors.red;
  static const Color logoRed = Color(0xFFE53935);
  static const Color logoAbu = Color(0xFF616161);
  static const Color logoBiru = Color(0xFF29B6F6);
}

class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppTheme.primary,
    fontFamily: 'Poppins',
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
    fontFamily: 'Poppins',
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppTheme.textSecondary,
    fontFamily: 'Poppins',
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    fontFamily: 'Poppins',
  );
}

// ✅ ThemeData global untuk MaterialApp
final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: AppTheme.background,
  primaryColor: AppTheme.primary,
  colorScheme: const ColorScheme.light(
    primary: AppTheme.primary,
    secondary: AppTheme.secondary,
    surface: AppTheme.surface,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: AppTheme.textPrimary,
    onError: Colors.white,
    error: AppTheme.error,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppTheme.primary,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
        fontFamily: 'Poppins'),
    headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
        fontFamily: 'Poppins'),
    bodyLarge: TextStyle(
        fontSize: 16, color: AppTheme.textPrimary, fontFamily: 'Poppins'),
    bodyMedium: TextStyle(
        fontSize: 14, color: AppTheme.textSecondary, fontFamily: 'Poppins'),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: AppTextStyles.button,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.secondary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.primary),
    ),
    labelStyle: const TextStyle(color: AppTheme.textPrimary),
  ),
);
