import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color deepGreen = Color(0xFF1F3B2C);
  static const Color softGold = Color(0xFFC9A24B);
  static const Color ivory = Color(0xFFFBF7EE);
  static const Color charcoal = Color(0xFF2C2C2C);
  static const Color subtle = Color(0xFF7A7A7A);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepGreen,
        onPrimary: AppColors.ivory,
        secondary: AppColors.softGold,
        onSecondary: AppColors.charcoal,
        surface: AppColors.ivory,
        onSurface: AppColors.charcoal,
      ),
      scaffoldBackgroundColor: AppColors.ivory,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.charcoal,
            displayColor: AppColors.deepGreen,
          )
          .copyWith(
            displayLarge: base.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.deepGreen,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.deepGreen,
            ),
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              color: AppColors.charcoal,
              height: 1.4,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.deepGreen,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: AppColors.ivory,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepGreen,
          side: const BorderSide(color: AppColors.softGold, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
