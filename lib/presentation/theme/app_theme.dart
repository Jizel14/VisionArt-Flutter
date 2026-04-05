import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryPurple,
        secondary: AppColors.primaryBlue,
        surface: AppColors.bgDark,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.border.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyLarge().copyWith(
          color: AppColors.textSecondary.withOpacity(0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.heading1(),
        headlineMedium: AppTypography.heading2(),
        bodyLarge: AppTypography.bodyLarge(),
        bodyMedium: AppTypography.bodySmall(),
        labelLarge: AppTypography.button(),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryPurple,
        secondary: AppColors.primaryBlue,
        surface: const Color(0xFFF8FAFC),
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.bgDark,
        onSurfaceVariant: const Color(0xFF64748B),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        iconTheme: const IconThemeData(color: AppColors.bgDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.border.withOpacity(0.2),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyLarge().copyWith(
          color: AppColors.textSecondary.withOpacity(0.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPurple,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.heading1().copyWith(color: AppColors.bgDark),
        headlineMedium: AppTypography.heading2().copyWith(color: AppColors.bgDark),
        bodyLarge: AppTypography.bodyLarge().copyWith(color: AppColors.bgDark),
        bodyMedium: AppTypography.bodySmall().copyWith(color: AppColors.bgDark),
        labelLarge: AppTypography.button(),
      ),
    );
  }
}
