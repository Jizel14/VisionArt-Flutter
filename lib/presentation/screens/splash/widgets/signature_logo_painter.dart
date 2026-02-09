import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Default VisionArt logo: a vein tree — one whole shape made of branching veins
/// (like human veins or tree veins). Single continuous path so draw-on animation works.
class SignatureLogoPainter extends CustomPainter {
  SignatureLogoPainter({
    required this.progress,
    this.strokeWidth = 2.8,
    this.color = Colors.white,
    this.useGradient = true,
  }) : super();

  /// 0.0 = nothing drawn, 1.0 = full vein tree visible.
  final double progress;
  final double strokeWidth;
  final Color color;
  final bool useGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 140;

    final path = _buildVeinTreePath(scale, center);
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    var totalLength = 0.0;
    for (final metric in pathMetrics) {
      totalLength += metric.length;
    }
    if (totalLength <= 0) return;

    final visibleLength = totalLength * progress.clamp(0.0, 1.0);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (useGradient) {
      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.lightBlue.withOpacity(0.95),
          color.withOpacity(0.92),
          color,
          AppColors.primaryPurple.withOpacity(0.85),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      paint.color = color;
    }

    var drawn = 0.0;
    for (final metric in pathMetrics) {
      if (drawn >= visibleLength) break;
      final len = metric.length;
      final end = (visibleLength - drawn).clamp(0.0, len);
      if (end > 0) {
        canvas.drawPath(metric.extractPath(0.0, end), paint);
      }
      drawn += len;
    }
  }

  /// Vein tree: trunk + branches (each contour drawn in order for morph-in).
  Path _buildVeinTreePath(double scale, Offset center) {
    final path = Path();
    final dx = center.dx;
    final dy = center.dy;
    final s = scale;

    // Root → trunk up to main fork
    path.moveTo(dx, dy + 32 * s);
    path.quadraticBezierTo(dx - 2 * s, dy + 12 * s, dx, dy - 8 * s);
    path.quadraticBezierTo(dx + 3 * s, dy - 22 * s, dx, dy - 28 * s);

    // Left main branch
    path.moveTo(dx, dy - 20 * s);
    path.quadraticBezierTo(dx - 18 * s, dy - 24 * s, dx - 28 * s, dy - 18 * s);
    path.quadraticBezierTo(dx - 32 * s, dy - 12 * s, dx - 30 * s, dy - 6 * s);
    path.moveTo(dx - 22 * s, dy - 22 * s);
    path.quadraticBezierTo(dx - 26 * s, dy - 26 * s, dx - 24 * s, dy - 28 * s);
    path.moveTo(dx - 26 * s, dy - 16 * s);
    path.quadraticBezierTo(dx - 30 * s, dy - 20 * s, dx - 32 * s, dy - 14 * s);

    // Right main branch
    path.moveTo(dx, dy - 20 * s);
    path.quadraticBezierTo(dx + 18 * s, dy - 24 * s, dx + 28 * s, dy - 18 * s);
    path.quadraticBezierTo(dx + 32 * s, dy - 12 * s, dx + 30 * s, dy - 6 * s);
    path.moveTo(dx + 22 * s, dy - 22 * s);
    path.quadraticBezierTo(dx + 26 * s, dy - 26 * s, dx + 24 * s, dy - 28 * s);
    path.moveTo(dx + 26 * s, dy - 16 * s);
    path.quadraticBezierTo(dx + 30 * s, dy - 20 * s, dx + 32 * s, dy - 14 * s);

    // Top center veins
    path.moveTo(dx, dy - 28 * s);
    path.quadraticBezierTo(dx - 4 * s, dy - 34 * s, dx - 6 * s, dy - 36 * s);
    path.moveTo(dx, dy - 28 * s);
    path.quadraticBezierTo(dx + 4 * s, dy - 34 * s, dx + 6 * s, dy - 36 * s);

    // Lower side veins
    path.moveTo(dx - 6 * s, dy + 4 * s);
    path.quadraticBezierTo(dx - 14 * s, dy + 2 * s, dx - 18 * s, dy + 8 * s);
    path.moveTo(dx + 6 * s, dy + 4 * s);
    path.quadraticBezierTo(dx + 14 * s, dy + 2 * s, dx + 18 * s, dy + 8 * s);

    return path;
  }

  @override
  bool shouldRepaint(covariant SignatureLogoPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.useGradient != useGradient;
  }
}
