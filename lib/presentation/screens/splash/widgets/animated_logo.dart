import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'signature_logo_painter.dart';

/// Splash logo: appears small then zooms in. Uses default signature path or user's saved signature image.
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    required this.animation,
    this.customSignatureBytes,
  });

  final Animation<double> animation;
  /// If set, this image is shown instead of the default drawn signature.
  final Uint8List? customSignatureBytes;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Appear little then zoom: scale 0.25 -> 1.0 over first ~500ms
        final scaleT = (animation.value * 2).clamp(0.0, 1.0);
        final scale = 0.25 + 0.75 * Curves.easeOut.transform(scaleT);
        final opacity = Curves.easeOut.transform(scaleT);

        // Draw-on (morph-in) for default vein tree: over ~40% of splash so it’s clearly visible
        const drawEnd = 0.4;
        final drawT = (animation.value / drawEnd).clamp(0.0, 1.0);
        final drawProgress = Curves.easeInOut.transform(drawT);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft glow (theme)
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          blurRadius: 60,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightBlue.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                  if (customSignatureBytes != null && customSignatureBytes!.isNotEmpty) ...[
                    ClipOval(
                      child: Image.memory(
                        customSignatureBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ] else
                    CustomPaint(
                      size: const Size(120, 120),
                      painter: SignatureLogoPainter(
                        progress: drawProgress,
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
