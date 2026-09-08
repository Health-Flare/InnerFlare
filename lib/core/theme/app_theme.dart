import 'package:flutter/material.dart';

/// Brand palette taken from the Inner Flare logo: warm cream, ember orange,
/// and the deep teal used behind the logo on the loading screen.
abstract final class AppColors {
  static const cream = Color(0xFFF3E9DB);
  static const emberOrange = Color(0xFFE0834A);
  static const softOrange = Color(0xFFF2B183);
  static const deepTeal = Color(0xFF17272C);
  static const midTeal = Color(0xFF2B4249);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.emberOrange,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.emberOrange,
          onPrimary: Colors.white,
          secondary: AppColors.deepTeal,
          surface: AppColors.cream,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.deepTeal,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: AppColors.deepTeal,
        displayColor: AppColors.deepTeal,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.emberOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emberOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
