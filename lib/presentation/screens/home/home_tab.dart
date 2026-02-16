import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/mock_image_urls.dart';
import '../../../core/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import '../report/report_screen.dart';
import 'post_detail_screen.dart';

/// Home tab: feed of mock posts — AI images, quotes, likes, comments, share.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.userName,
    this.isLoading = false,
    required this.onToggleTheme,
    required this.authService,
  });

  final String userName;
  final bool isLoading;
  final VoidCallback onToggleTheme;
  final AuthService authService;

  static final List<Map<String, dynamic>> mockPosts = [
    {
      'author': 'Alex',
      'avatarEmoji': '🎨',
      'quote': 'Art is the only way to run away without leaving home.',
      'imageColor': 0xFF7C3AED,
      'imageUrl': MockImageUrls.at(0),
      'likes': 24,
      'comments': 5,
      'time': '2h ago',
    },
    {
      'author': 'Jordan',
      'avatarEmoji': '✨',
      'quote': 'Every child is an artist. The problem is staying an artist.',
      'imageColor': 0xFF3B82F6,
      'imageUrl': MockImageUrls.at(1),
      'likes': 18,
      'comments': 3,
      'time': '5h ago',
    },
    {
      'author': 'Sam',
      'avatarEmoji': '🌿',
      'quote': 'Creativity takes courage.',
      'imageColor': 0xFF10B981,
      'imageUrl': MockImageUrls.at(2),
      'likes': 42,
      'comments': 12,
      'time': '1d ago',
    },
    {
      'author': 'Riley',
      'avatarEmoji': '🌃',
      'quote': 'The world always seems brighter when you’ve just made something.',
      'imageColor': 0xFFEC4899,
      'imageUrl': MockImageUrls.at(3),
      'likes': 31,
      'comments': 8,
      'time': '2d ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    return SmokeBackground(
      child: SafeArea(
        child: isLoading
            ? _buildShimmer(context)
            : CustomScrollView(
                slivers: [
                  // Header: greeting + followers + theme toggle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, $userName',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.people_rounded,
                                      size: 18,
                                      color: textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '128 followers · 12 posts',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onToggleTheme,
                            icon: Icon(
                              context.isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              color: textPrimary,
                            ),
                            tooltip: context.isDark
                                ? 'Switch to light mode'
                                : 'Switch to dark mode',
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Text(
                        'Feed',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  // Feed list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: AnimationLimiter(
                      child: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = mockPosts[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 400),
                              child: SlideAnimation(
                                verticalOffset: 30,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: _FeedCard(
                                      author: post['author'] as String,
                                      avatarEmoji: post['avatarEmoji'] as String,
                                      quote: post['quote'] as String,
                                      imageUrl: post['imageUrl'] as String?,
                                      imageColor: Color(post['imageColor'] as int),
                                      likes: post['likes'] as int,
                                      comments: post['comments'] as int,
                                      time: post['time'] as String,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                      onReport: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ReportScreen(
                                              authService: authService,
                                              initialType: 'artwork',
                                              targetId: 'post-$index',
                                              targetLabel: post['quote'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                      onTap: () {
                                        Navigator.of(context).push(
                                          PostDetailScreen.route(
                                            PostDetailScreen(
                                              author: post['author'] as String,
                                              avatarEmoji: post['avatarEmoji'] as String,
                                              quote: post['quote'] as String,
                                              imageUrl: post['imageUrl'] as String?,
                                              imageColor: Color(post['imageColor'] as int),
                                              likes: post['likes'] as int,
                                              comments: post['comments'] as int,
                                              time: post['time'] as String,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: mockPosts.length,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final border = context.borderColor;
    final secondary = context.textSecondaryColor;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: border,
            highlightColor: secondary.withOpacity(0.3),
            child: Container(
              height: 32,
              width: 200,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Shimmer.fromColors(
            baseColor: border,
            highlightColor: secondary.withOpacity(0.3),
            child: Container(
              height: 18,
              width: 160,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Shimmer.fromColors(
            baseColor: border,
            highlightColor: secondary.withOpacity(0.3),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: border,
            highlightColor: secondary.withOpacity(0.3),
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: border,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.author,
    required this.avatarEmoji,
    required this.quote,
    this.imageUrl,
    required this.imageColor,
    required this.likes,
    required this.comments,
    required this.time,
    required this.textPrimary,
    required this.textSecondary,
    this.onTap,
    this.onReport,
  });

  final String author;
  final String avatarEmoji;
  final String quote;
  final String? imageUrl;
  final Color imageColor;
  final int likes;
  final int comments;
  final String time;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onTap;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final cardBg = context.cardBackgroundColor;
    final border = context.borderColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryPurple.withOpacity(0.3),
                    child: Text(avatarEmoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          time,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // AI-generated image (network or gradient fallback)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 180,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: imageColor,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
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
            ),
            // Quote
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                '"$quote"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
            // Actions: like, comment, share
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              child: Row(
                children: [
                  _ActionChip(
                    icon: Icons.favorite_rounded,
                    label: '$likes',
                    color: AppColors.accentPink,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _ActionChip(
                    icon: Icons.chat_bubble_rounded,
                    label: '$comments',
                    color: AppColors.primaryBlue,
                    onTap: () {},
                  ),
                  const SizedBox(width: 16),
                  _ActionChip(
                    icon: Icons.report_rounded,
                    label: '!',
                    color: AppColors.error.withOpacity(0.7),
                    onTap: onReport ?? () {},
                  ),
                  const Spacer(),
                  _ActionChip(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    color: textSecondary,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
