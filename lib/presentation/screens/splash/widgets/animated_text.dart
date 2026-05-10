import 'package:flutter/material.dart';
import '../../../theme/app_typography.dart';

/// "VisionArt" + tagline with staggered slide up and fade (400-1200ms, 1200-2200ms).
class AnimatedTextWidget extends StatelessWidget {
  const AnimatedTextWidget({super.key, required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    // Title: 400-1200ms -> 0.133 to 0.4
    final titleT = ((animation.value - 0.133) / 0.267).clamp(0.0, 1.0);
    final titleOpacity = Curves.easeOut.transform(titleT);
    final titleOffset = 30 * (1 - Curves.easeOut.transform(titleT));

    // Tagline: 1200-2200ms -> 0.4 to 0.733
    final tagT = ((animation.value - 0.4) / 0.333).clamp(0.0, 1.0);
    final tagOpacity = Curves.easeOut.transform(tagT);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: Offset(0, titleOffset),
          child: Opacity(
            opacity: titleOpacity,
            child: Text(
              'VisionArt',
              style: AppTypography.appTitle(context),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Opacity(
          opacity: tagOpacity,
          child: Text(
            'Your Context, Your Art',
            style: AppTypography.tagline(context),
          ),
        ),
      ],
    );
  }
}
