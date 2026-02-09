import 'package:flutter/material.dart';
import 'package:zhi_starry_sky/starry_sky.dart';
import '../../../theme/app_colors.dart';

/// Full-screen background using [zhi_starry_sky] starry sky animation.
/// Respects light/dark mode via [Theme.brightness] and adds a brand gradient overlay.
/// See: https://pub.dev/packages/zhi_starry_sky
class SmokeBackground extends StatelessWidget {
  const SmokeBackground({
    super.key,
    required this.child,
    this.useGradientOverlay = true,
  });

  final Widget child;

  /// When true, applies a purple/blue gradient overlay (dark) or subtle tint (light) to match app theme.
  final bool useGradientOverlay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Starry sky (uses Theme.brightness: dark = black + white stars, light = white + black stars)
          const Positioned.fill(
            child: StarrySkyView(),
          ),
          // Brand gradient overlay: purple/blue in dark, very subtle in light
          if (useGradientOverlay)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.primaryPurple.withOpacity(0.45),
                            AppColors.primaryBlue.withOpacity(0.35),
                            AppColors.darkPurple.withOpacity(0.5),
                          ]
                        : [
                            AppColors.lightBlue.withOpacity(0.08),
                            AppColors.primaryPurple.withOpacity(0.05),
                          ],
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
