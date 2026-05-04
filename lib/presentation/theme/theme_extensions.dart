import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware colors so text and surfaces look correct in both light and dark mode.
class AppThemeColors {
  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.textSecondary
          : const Color(0xFF64748B);

  /// Background for nav bar, app bars, cards that need to stand out.
  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.bgDark
          : const Color(0xFFF8FAFC);

  /// Card / glass panel background.
  static Color cardBackgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.bgDark.withOpacity(0.85)
          : Colors.white.withOpacity(0.92);

  /// Border for cards and inputs in light mode.
  static Color borderColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.border
          : const Color(0xFFE2E8F0);

  static bool isDark(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark;
}
