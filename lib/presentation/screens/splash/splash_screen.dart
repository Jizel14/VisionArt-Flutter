import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'widgets/smoke_background.dart';
import 'widgets/animated_logo.dart';
import 'widgets/particle_widget.dart';
import 'widgets/animated_text.dart';

/// Splash: logo appears small and zooms in (default or user signature), then particles, title, tagline, navigate.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.signatureBytes,
  });

  final VoidCallback onComplete;
  /// User's saved signature image; if null, default designed signature is shown.
  final Uint8List? signatureBytes;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 3200);
  static const _navAt = 3000;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _duration,
      vsync: this,
    )..forward();

    Future.delayed(const Duration(milliseconds: _navAt), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SmokeBackground(
      child: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo (center): small then zoom; default or user signature
            AnimatedLogo(
              animation: _controller,
              customSignatureBytes: widget.signatureBytes,
            ),
            // Particles around logo (staggered 200-700ms)
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.5 - 80,
              top: MediaQuery.sizeOf(context).height * 0.5 - 100,
              child: ParticleWidget(
                animation: _controller,
                delay: 0.06,
                size: 6,
                offset: const Offset(20, 30),
              ),
            ),
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.5 + 50,
              top: MediaQuery.sizeOf(context).height * 0.5 - 80,
              child: ParticleWidget(
                animation: _controller,
                delay: 0.12,
                size: 5,
                offset: const Offset(-10, 20),
              ),
            ),
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.5 - 60,
              top: MediaQuery.sizeOf(context).height * 0.5 + 60,
              child: ParticleWidget(
                animation: _controller,
                delay: 0.18,
                size: 7,
                offset: const Offset(30, -20),
              ),
            ),
            Positioned(
              left: MediaQuery.sizeOf(context).width * 0.5 + 30,
              top: MediaQuery.sizeOf(context).height * 0.5 + 40,
              child: ParticleWidget(
                animation: _controller,
                delay: 0.22,
                size: 5,
                offset: const Offset(-20, -10),
              ),
            ),
            // Text below logo (40dp spacing per spec)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.sizeOf(context).height * 0.5 + 100,
              child: AnimatedTextWidget(animation: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
