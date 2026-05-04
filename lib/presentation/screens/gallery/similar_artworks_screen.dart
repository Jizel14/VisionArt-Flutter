import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

import '../../../core/models/artwork_model.dart';
import '../../../core/services/artwork_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// Full-screen page displaying artworks similar to a given artwork.
/// Navigated to from the artwork details bottom sheet via the "Similar" button.
class SimilarArtworksScreen extends StatefulWidget {
  const SimilarArtworksScreen({super.key, required this.artwork});

  final ArtworkModel artwork;

  @override
  State<SimilarArtworksScreen> createState() => _SimilarArtworksScreenState();
}

class _SimilarArtworksScreenState extends State<SimilarArtworksScreen> {
  final _artworkService = ArtworkService();
  List<ArtworkModel> _similarArtworks = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadSimilar();
  }

  Future<void> _loadSimilar() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final similar = await _artworkService.getSimilarArtworks(
        widget.artwork.id,
        limit: 9,
        generate: true,
      );
      if (mounted) {
        setState(() {
          _similarArtworks = similar;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  ImageProvider? _imageProviderFor(ArtworkModel artwork) {
    if (artwork.imageUrl.startsWith('data:image')) {
      final b64 = artwork.imageUrl.split(',').last;
      return MemoryImage(base64Decode(b64));
    } else if (artwork.imageUrl.startsWith('http')) {
      return NetworkImage(artwork.imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourceImage = _imageProviderFor(widget.artwork);

    return Scaffold(
      backgroundColor: AppThemeColors.surfaceColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Collapsible App Bar with source artwork ─────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            stretch: true,
            backgroundColor: AppThemeColors.surfaceColor(context),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'More Like This',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 0.3,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (sourceImage != null)
                    Image(image: sourceImage, fit: BoxFit.cover),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppThemeColors.surfaceColor(context).withOpacity(0.3),
                          AppThemeColors.surfaceColor(context),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Blur layer
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // Source artwork thumbnail
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(bottom: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: sourceImage != null
                          ? Image(image: sourceImage, fit: BoxFit.cover)
                          : Container(color: AppColors.border),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Subtitle ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurple.withOpacity(0.2),
                              AppColors.primaryBlue.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.auto_awesome_mosaic_rounded,
                            size: 18, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Discover similar artworks',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppThemeColors.textPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Based on style & content of "${widget.artwork.title ?? 'your artwork'}"',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppThemeColors.textSecondaryColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppThemeColors.borderColor(context).withOpacity(0.5)),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          if (_loading)
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _ShimmerCard(isDark: isDark, index: index),
                  childCount: 6,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.78,
                ),
              ),
            )
          else if (_hasError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildErrorState(),
            )
          else if (_similarArtworks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(isDark),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final art = _similarArtworks[index];
                    return FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: Duration(milliseconds: (index % 6) * 100),
                      child: _SimilarArtworkCard(
                        artwork: art,
                        imageProvider: _imageProviderFor(art),
                        isDark: isDark,
                        onTap: () => _openArtworkDetail(context, art),
                      ),
                    );
                  },
                  childCount: _similarArtworks.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.78,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openArtworkDetail(BuildContext context, ArtworkModel artwork) {
    // Open a lightweight detail dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SimilarDetailSheet(
        artwork: artwork,
        imageProvider: _imageProviderFor(artwork),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.error),
          ),
          const SizedBox(height: 24),
          Text(
            'Could not load similar artworks',
            style: TextStyle(
              color: AppThemeColors.textPrimaryColor(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(
              color: AppThemeColors.textSecondaryColor(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadSimilar,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.15),
                    AppColors.primaryBlue.withOpacity(0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.explore_outlined,
                  size: 56,
                  color: AppThemeColors.textSecondaryColor(context)
                      .withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'No similar artworks found',
              style: TextStyle(
                color: AppThemeColors.textPrimaryColor(context),
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate more artworks to build your collection!',
              style: TextStyle(
                color: AppThemeColors.textSecondaryColor(context),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Similar Artwork Card
// ═══════════════════════════════════════════════════════════════════════════════
class _SimilarArtworkCard extends StatelessWidget {
  const _SimilarArtworkCard({
    required this.artwork,
    required this.imageProvider,
    required this.isDark,
    required this.onTap,
  });

  final ArtworkModel artwork;
  final ImageProvider? imageProvider;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (imageProvider != null)
              Image(image: imageProvider!, fit: BoxFit.cover)
            else
              Container(color: AppThemeColors.borderColor(context)),

            // Bottom gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: const Alignment(0.0, 0.15),
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Sparkle badge
            Positioned(
              top: 10,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 14, color: Colors.white70),
                  ),
                ),
              ),
            ),

            // Info at bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (artwork.title != null)
                    Text(
                      artwork.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (artwork.description != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      artwork.description!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 10,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        artwork.isLikedByMe
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 12,
                        color: artwork.isLikedByMe
                            ? AppColors.accentPink
                            : Colors.white60,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${artwork.likesCount}',
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shimmer placeholder card
// ═══════════════════════════════════════════════════════════════════════════════
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({required this.isDark, required this.index});

  final bool isDark;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 800 + index * 200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [Colors.white10, Colors.white.withOpacity(0.04)]
                    : [
                        Colors.black.withOpacity(0.06),
                        Colors.black.withOpacity(0.02)
                      ],
              ),
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.15),
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Lightweight Sheet for viewing a similar artwork
// ═══════════════════════════════════════════════════════════════════════════════
class _SimilarDetailSheet extends StatelessWidget {
  const _SimilarDetailSheet({
    required this.artwork,
    required this.imageProvider,
  });

  final ArtworkModel artwork;
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: AppThemeColors.textSecondaryColor(context)
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InteractiveViewer(
                      child: imageProvider != null
                          ? Image(
                              image: imageProvider!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(height: 300, color: AppColors.border),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  if (artwork.title != null)
                    Text(
                      artwork.title!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppThemeColors.textPrimaryColor(context),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Description / Prompt
                  if (artwork.description != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppThemeColors.borderColor(context)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROMPT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artwork.description!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppThemeColors.textPrimaryColor(context)
                                  .withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Stats row
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.favorite_rounded,
                          size: 16, color: AppColors.accentPink),
                      const SizedBox(width: 4),
                      Text(
                        '${artwork.likesCount} likes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppThemeColors.textSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: AppThemeColors.textSecondaryColor(context)),
                      const SizedBox(width: 4),
                      Text(
                        '${artwork.commentsCount} comments',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppThemeColors.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
