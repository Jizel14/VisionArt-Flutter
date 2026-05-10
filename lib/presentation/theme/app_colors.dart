import 'package:flutter/material.dart';

/// VisionArt color system - purple/blue gradient theme, dark background.
abstract class AppColors {
  // Primary gradient
  static const Color primaryPurple = Color(0xFF7C3AED);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color darkPurple = Color(0xFF5B21B6);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color accentPink = Color(0xFFEC4899);

  // Neutrals
  static const Color bgDark = Color(0xFF0F172A);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFCBD5E1);
  static const Color border = Color(0xFF1E293B);

  // State
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Web3 / Marketplace
  static const Color ethGold = Color(0xFFF59E0B);
  static const Color chainCyan = Color(0xFF22D3EE);
  static const Color nftAccent = Color(0xFFA78BFA);
  static const Color polygonPurple = Color(0xFF8B5CF6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryBlue],
  );

  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primaryPurple, primaryBlue],
  );

  // Shadows
  static List<BoxShadow> shadowSmall(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowMedium(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> shadowLarge(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 24,
          spreadRadius: 5,
          offset: Offset.zero,
        ),
      ];
}
