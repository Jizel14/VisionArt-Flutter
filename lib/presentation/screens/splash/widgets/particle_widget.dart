import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Single floating particle - 5-8dp, staggered animation.
class ParticleWidget extends StatelessWidget {
  const ParticleWidget({
    super.key,
    required this.animation,
    this.delay = 0.0,
    this.size = 6.0,
    this.offset = Offset.zero,
  });

  final Animation<double> animation;
  final double delay;
  final double size;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = (animation.value - delay).clamp(0.0, 1.0);
        if (t <= 0) return const SizedBox.shrink();
        final opacity = Curves.easeOut.transform(t);
        final y = 8 * math.sin((animation.value + delay) * 2 * math.pi);
        final x = 4 * math.cos((animation.value + delay) * 1.5 * math.pi);
        return Transform.translate(
          offset: Offset(offset.dx + x, offset.dy + y),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textPrimary.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 4,
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
