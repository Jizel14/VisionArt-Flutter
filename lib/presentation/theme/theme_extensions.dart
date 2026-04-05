import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware colors so text and surfaces look correct in both light and dark mode.
extension ThemeColors on BuildContext {
  Color get textPrimaryColor =>
      Theme.of(this).colorScheme.onSurface;

  Color get textSecondaryColor =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.textSecondary
          : const Color(0xFF64748B);

  /// Background for nav bar, app bars, cards that need to stand out.
  Color get surfaceColor =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.bgDark
          : const Color(0xFFF8FAFC);

  /// Card / glass panel background.
  Color get cardBackgroundColor =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.bgDark.withOpacity(0.85)
          : Colors.white.withOpacity(0.92);

  /// Border for cards and inputs in light mode.
  Color get borderColor =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColors.border
          : const Color(0xFFE2E8F0);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
