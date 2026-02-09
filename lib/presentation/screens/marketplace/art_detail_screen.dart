import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// Full-screen art detail with open/close animation and Web3 details.
class ArtDetailScreen extends StatefulWidget {
  const ArtDetailScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.price,
    required this.currency,
    this.priceUsd,
    this.imageUrl,
    required this.imageColor,
    required this.negotiable,
  });

  final String title;
  final String artist;
  final String price;
  final String currency;
  final String? priceUsd;
  final String? imageUrl;
  final Color imageColor;
  final bool negotiable;

  static PageRouteBuilder route(ArtDetailScreen screen) {
    return PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) {
        final fade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        final scale = Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: scale,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<ArtDetailScreen> createState() => _ArtDetailScreenState();
}

class _ArtDetailScreenState extends State<ArtDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 400,
                          maxHeight: MediaQuery.of(context).size.height * 0.82,
                        ),
                        decoration: BoxDecoration(
                          color: context.cardBackgroundColor.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.chainCyan.withOpacity(0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.polygonPurple.withOpacity(0.25),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Stack(
                                children: [
                                  _AnimatedArtImage(
                                    imageUrl: widget.imageUrl,
                                    imageColor: widget.imageColor,
                                    pulse: _pulseController,
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.nftAccent.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.token_rounded,
                                              size: 16, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            'NFT',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: IconButton.filled(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      icon: const Icon(Icons.close_rounded),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black38,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.fingerprint_rounded,
                                            size: 16, color: textSecondary),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.artist,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: textSecondary,
                                                fontFamily: 'monospace',
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'AI-generated · Listed on chain',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.chainCyan
                                                .withOpacity(0.9),
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(Icons.monetization_on_rounded,
                                            color: AppColors.ethGold, size: 24),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${widget.price} ${widget.currency}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                color: AppColors.ethGold,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        if (widget.priceUsd != null &&
                                            widget.priceUsd!.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Text(
                                            widget.priceUsd!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color: textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () {},
                                            icon: const Icon(
                                                Icons.shopping_bag_rounded,
                                                size: 20),
                                            label: const Text('Buy now'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.chainCyan,
                                              foregroundColor: Colors.black87,
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: widget.negotiable
                                                ? () {}
                                                : null,
                                            icon: const Icon(
                                                Icons.handshake_rounded,
                                                size: 18),
                                            label: Text(
                                              widget.negotiable
                                                  ? 'Negotiate'
                                                  : 'Fixed',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.ethGold,
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 14),
                                              side: BorderSide(
                                                  color: AppColors.ethGold
                                                      .withOpacity(0.7)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedArtImage extends StatelessWidget {
  const _AnimatedArtImage({
    this.imageUrl,
    required this.imageColor,
    required this.pulse,
  });

  final String? imageUrl;
  final Color imageColor;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final scale = 0.98 + 0.04 * pulse.value;
        return Transform.scale(
          scale: scale,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              width: double.infinity,
              color: imageColor,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Center(
                        child: Icon(
                          Icons.auto_awesome,
                          size: 56,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(
                          Icons.auto_awesome,
                          size: 56,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        Icons.auto_awesome,
                        size: 56,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
