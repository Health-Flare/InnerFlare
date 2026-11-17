import 'package:flutter/material.dart';

/// Health-Flare brand v2.0 tokens, scoped to Inner Flare's product colour
/// (Rose). See docs/brand/README.md and the canonical guidelines pinned
/// there (Health-Flare/brand repo, tag v2.0.0, brand-guidelines.md).
abstract final class AppColors {
  /// Inner Flare's primary brand colour: marks, primary actions, 24px+
  /// type. White on it holds 4.0:1 contrast.
  static const rose = Color(0xFFD2546E);

  /// A light tint of [rose] for fills and icon badges on light grounds
  /// (cards, calendar cells) where the full-strength colour would be too
  /// loud. Not a brand-guideline token on its own, derived from Rose.
  static const roseTint = Color(0xFFEBC0CB);

  /// Links and accented text on light grounds (5.3:1 on Dawn).
  static const deepRose = Color(0xFFB0404F);

  /// The mark's colour on dark grounds only (8.1:1 on Ink). Never on light
  /// grounds.
  static const amber = Color(0xFFF2A33A);

  /// Primary text colour; also the dark ground for the "Dusk" scheme.
  static const ink = Color(0xFF221C18);

  /// A near-black tint of [ink] for the far end of dark-ground gradients.
  static const inkDeep = Color(0xFF0F0C0A);

  /// Secondary text (5.9:1 on Dawn).
  static const slate = Color(0xFF6B5E54);

  /// Default light background.
  static const dawn = Color(0xFFFBF7F2);

  /// Surfaces: cards and elevated fills on top of [dawn].
  static const sand = Color(0xFFF3E9DD);
}

abstract final class AppTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.rose,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.rose,
          onPrimary: Colors.white,
          secondary: AppColors.deepRose,
          surface: AppColors.sand,
        );

    const fraunces = 'Fraunces';
    const dmSans = 'DM Sans';

    final baseTextTheme = ThemeData.light().textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
      fontFamily: dmSans,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.dawn,
      fontFamily: dmSans,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: fraunces,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        // Display/headline/title styles carry the wordmark typeface;
        // body/label stays DM Sans for interface text and numbers.
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontFamily: fraunces,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rose,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: dmSans,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.rose,
        foregroundColor: Colors.white,
      ),
    );
  }
}
