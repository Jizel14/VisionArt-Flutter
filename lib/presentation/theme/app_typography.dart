import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// VisionArt typography - Poppins for headings, Inter for body.
/// [context] is optional (e.g. null when building ThemeData).
abstract class AppTypography {
  // App title (splash, headers)
  static TextStyle appTitle([BuildContext? context]) => GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  // Headings
  static TextStyle heading1([BuildContext? context]) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  static TextStyle heading2([BuildContext? context]) => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  // Body
  static TextStyle bodyLarge([BuildContext? context]) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textPrimary,
      );

  static TextStyle bodySmall([BuildContext? context]) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // Button
  static TextStyle button([BuildContext? context]) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  // Tagline
  static TextStyle tagline([BuildContext? context]) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: AppColors.textSecondary,
      );
}
