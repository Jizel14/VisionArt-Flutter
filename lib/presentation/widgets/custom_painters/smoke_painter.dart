import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Wave-shaped smoke in purple and blue. Use with AnimationController.
class SmokeBackgroundPainter extends CustomPainter {
  SmokeBackgroundPainter({
    required this.animation,
  }) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;

    // Wave 1 - purple, top to middle
    _drawWave(
      canvas,
      size: size,
      baseY: size.height * 0.15,
      amplitude: size.height * 0.12,
      wavelength: size.width * 0.8,
      phase: t,
      color: AppColors.primaryPurple.withOpacity(0.5),
      waveHeight: size.height * 0.35,
    );

    // Wave 2 - blue, middle
    _drawWave(
      canvas,
      size: size,
      baseY: size.height * 0.45,
      amplitude: size.height * 0.14,
      wavelength: size.width * 0.7,
      phase: t + 1.2,
      color: AppColors.primaryBlue.withOpacity(0.45),
      waveHeight: size.height * 0.4,
    );

    // Wave 3 - light purple, bottom
    _drawWave(
      canvas,
      size: size,
      baseY: size.height * 0.75,
      amplitude: size.height * 0.1,
      wavelength: size.width * 0.9,
      phase: t + 2.5,
      color: AppColors.lightBlue.withOpacity(0.4),
      waveHeight: size.height * 0.4,
    );

    // Soft blob overlays for smoke feel
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = AppColors.primaryPurple.withOpacity(0.2);
    canvas.drawCircle(
      Offset(size.width * (0.3 + 0.08 * math.sin(t)), size.height * 0.3),
      size.width * 0.4,
      paint,
    );
    paint.color = AppColors.primaryBlue.withOpacity(0.2);
    canvas.drawCircle(
      Offset(size.width * (0.7 + 0.06 * math.cos(t + 1)), size.height * 0.65),
      size.width * 0.45,
      paint,
    );
  }

  void _drawWave(
    Canvas canvas, {
    required Size size,
    required double baseY,
    required double amplitude,
    required double wavelength,
    required double phase,
    required Color color,
    required double waveHeight,
  }) {
    final path = Path();
    final firstY = baseY +
        amplitude * math.sin(phase) +
        amplitude * 0.5 * math.sin(phase * 1.3);
    path.moveTo(0, firstY);

    for (double x = 8; x <= size.width + 50; x += 8) {
      final y = baseY +
          amplitude * math.sin((x / wavelength) * 2 * math.pi + phase) +
          amplitude * 0.5 * math.sin((x / (wavelength * 0.7)) * 2 * math.pi + phase * 1.3);
      path.lineTo(x, y);
    }

    path.lineTo(size.width + 50, size.height + 50);
    path.lineTo(-50, size.height + 50);
    path.lineTo(0, firstY);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant SmokeBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Soft colorful smoke blobs for use inside cards (e.g. auth card).
/// Purple, blue, and pink blobs that drift slowly.
class CardSmokePainter extends CustomPainter {
  CardSmokePainter({
    required this.animation,
  }) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * math.pi;
    final w = size.width;
    final h = size.height;
    final s = size.shortestSide;

    _blob(canvas, w * (0.2 + 0.05 * math.sin(t)), h * 0.35, s * 0.35, AppColors.primaryPurple.withOpacity(0.22));
    _blob(canvas, w * (0.65 + 0.04 * math.cos(t + 1)), h * 0.5, s * 0.4, AppColors.primaryBlue.withOpacity(0.18));
    _blob(canvas, w * (0.5 + 0.06 * math.sin(t + 2)), h * 0.7, s * 0.25, AppColors.accentPink.withOpacity(0.12));
    _blob(canvas, w * (0.15 + 0.03 * math.cos(t * 0.8)), h * 0.2, s * 0.45, AppColors.lightBlue.withOpacity(0.15));
    _blob(canvas, w * (0.8 + 0.04 * math.sin(t + 0.5)), h * 0.75, s * 0.55, AppColors.darkPurple.withOpacity(0.1));
  }

  void _blob(Canvas canvas, double cx, double cy, double radius, Color color) {
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CardSmokePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
