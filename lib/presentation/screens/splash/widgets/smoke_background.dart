import 'package:flutter/material.dart';
import 'dart:math';

class SmokeBackground extends StatefulWidget {
  final Widget? child;
  const SmokeBackground({super.key, this.child});

  @override
  State<SmokeBackground> createState() => _SmokeBackgroundState();
}

class _SmokeBackgroundState extends State<SmokeBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SmokeParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          for (var p in _particles) {
            p.update();
          }
        });
      })..repeat();

    for (int i = 0; i < 20; i++) {
        _particles.add(SmokeParticle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: SmokePainter(_particles),
          child: Container(),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class SmokeParticle {
  late double x, y, size, opacity, speedX, speedY;
  final Random random;

  SmokeParticle(this.random) {
    reset();
  }

  void reset() {
    x = random.nextDouble() * 400;
    y = random.nextDouble() * 800;
    size = random.nextDouble() * 150 + 50;
    opacity = random.nextDouble() * 0.1 + 0.05;
    speedX = (random.nextDouble() - 0.5) * 0.5;
    speedY = (random.nextDouble() - 0.5) * 0.5;
  }

  void update() {
    x += speedX;
    y += speedY;
    if (x < -100 || x > 500 || y < -100 || y > 900) {
      reset();
    }
  }
}

class SmokePainter extends CustomPainter {
  final List<SmokeParticle> particles;
  SmokePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    for (var p in particles) {
      paint.color = Colors.blueGrey.withOpacity(p.opacity);
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
