import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/mock_image_urls.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import 'art_detail_screen.dart';

/// Marketplace: buy/sell AI art with Web3 / NFT feel. Price + Buy or Negotiate.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  static final List<Map<String, dynamic>> _mockListings = [
    {
      'id': '1',
      'title': 'Cosmic Drift',
      'artist': '0x7a3f...9e2c',
      'price': '0.08',
      'currency': 'ETH',
      'priceUsd': '~ \$240',
      'imageColor': 0xFF7C3AED,
      'imageUrl': MockImageUrls.at(4),
      'negotiable': true,
    },
    {
      'id': '2',
      'title': 'Neon Dreams',
      'artist': '0x4b2c...1a9d',
      'price': '120',
      'currency': '\$ART',
      'priceUsd': '',
      'imageColor': 0xFFEC4899,
      'imageUrl': MockImageUrls.at(5),
      'negotiable': true,
    },
    {
      'id': '3',
      'title': 'Abstract Pulse',
      'artist': '0x9e1f...4c7b',
      'price': '0.05',
      'currency': 'ETH',
      'priceUsd': '~ \$150',
      'imageColor': 0xFF3B82F6,
      'imageUrl': MockImageUrls.at(6),
      'negotiable': false,
    },
    {
      'id': '4',
      'title': 'Serenity #42',
      'artist': '0x2d8a...b3e1',
      'price': '85',
      'currency': '\$ART',
      'priceUsd': '',
      'imageColor': 0xFF10B981,
      'imageUrl': MockImageUrls.at(7),
      'negotiable': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return SmokeBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.ethGold.withOpacity(0.3),
                                AppColors.chainCyan.withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.ethGold.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.ethGold,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Marketplace',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Buy & sell AI art · NFT',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.chainCyan.withOpacity(0.95),
                                      letterSpacing: 0.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    _Pill(
                      icon: Icons.sell_rounded,
                      label: 'For sale',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    _Pill(
                      icon: Icons.handshake_rounded,
                      label: 'Negotiate',
                      color: AppColors.ethGold,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _mockListings[index];
                    return _ListingCard(
                      title: item['title'] as String,
                      artist: item['artist'] as String,
                      price: item['price'] as String,
                      currency: item['currency'] as String,
                      priceUsd: item['priceUsd'] as String?,
                      imageUrl: item['imageUrl'] as String?,
                      imageColor: Color(item['imageColor'] as int),
                      negotiable: item['negotiable'] as bool,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      onTap: () {
                        Navigator.of(context).push(
                          ArtDetailScreen.route(
                            ArtDetailScreen(
                              title: item['title'] as String,
                              artist: item['artist'] as String,
                              price: item['price'] as String,
                              currency: item['currency'] as String,
                              priceUsd: item['priceUsd'] as String?,
                              imageUrl: item['imageUrl'] as String?,
                              imageColor: Color(item['imageColor'] as int),
                              negotiable: item['negotiable'] as bool,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _mockListings.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.title,
    required this.artist,
    required this.price,
    required this.currency,
    this.priceUsd,
    this.imageUrl,
    required this.imageColor,
    required this.negotiable,
    required this.textPrimary,
    required this.textSecondary,
    this.onTap,
  });

  final String title;
  final String artist;
  final String price;
  final String currency;
  final String? priceUsd;
  final String? imageUrl;
  final Color imageColor;
  final bool negotiable;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardBg = context.cardBackgroundColor;
    final border = context.borderColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.chainCyan.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.polygonPurple.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: border.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 160,
                      width: double.infinity,
                      color: imageColor,
                      child: imageUrl != null && imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 160,
                              placeholder: (_, __) => Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.auto_awesome,
                                size: 48,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.nftAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.token_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'NFT',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Listed',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 14, color: textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            artist,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: textSecondary,
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.monetization_on_rounded, color: AppColors.ethGold, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '$price $currency',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.ethGold,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (priceUsd != null && priceUsd!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              priceUsd!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: textSecondary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.shopping_bag_rounded, size: 18),
                              label: const Text('Buy'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.chainCyan,
                                side: BorderSide(color: AppColors.chainCyan.withOpacity(0.7)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: negotiable ? () {} : null,
                              icon: const Icon(Icons.handshake_rounded, size: 18),
                              label: Text(negotiable ? 'Negotiate' : 'Fixed'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.ethGold,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
    );
  }
}
