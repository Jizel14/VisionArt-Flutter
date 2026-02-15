import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/services/artwork_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/models/artwork_model.dart';
import '../../../core/models/user_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import 'post_detail_screen.dart';
import '../profile/profile_inspect_screen.dart';

/// Home tab: live feed from backend with follow functionality
class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.userName,
    this.isLoading = false,
    required this.onToggleTheme,
    required this.currentUser,
  });

  final String userName;
  final bool isLoading;
  final VoidCallback onToggleTheme;
  final UserModel? currentUser;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late ArtworkService _artworkService;
  late FollowService _followService;
  late ScrollController _scrollController;

  List<ArtworkModel> _artworks = [];
  bool _isLoadingFeed = false;
  bool _hasMore = true;
  int _currentPage = 1;
  Map<String, bool> _followingMap = {}; // Track follow status per user

  @override
  void initState() {
    super.initState();
    _artworkService = ArtworkService();
    _followService = FollowService();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadFeed();
    }
  }

  Future<void> _loadFeed() async {
    if (_isLoadingFeed || !_hasMore) return;

    setState(() => _isLoadingFeed = true);

    try {
      final result = await _artworkService.getPublicFeed(
        page: _currentPage,
        limit: 10,
        sort: 'recent',
      );

      setState(() {
        _artworks.addAll(result.data);
        _isLoadingFeed = false;
        _hasMore = _currentPage < result.totalPages;
        _currentPage++;
      });
    } catch (e) {
      print('Error loading feed: $e');
      setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _toggleFollow(String userId, int index) async {
    try {
      final isCurrentlyFollowing = _followingMap[userId] ?? false;

      if (isCurrentlyFollowing) {
        await _followService.unfollowUser(userId);
        setState(() => _followingMap[userId] = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unfollowed successfully'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _followService.followUser(userId);
        setState(() => _followingMap[userId] = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Followed successfully'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling follow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return SmokeBackground(
      child: SafeArea(
        child: widget.isLoading
            ? _buildShimmer(context)
            : CustomScrollView(
                controller: _scrollController,
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
                                  'Welcome, ${widget.userName}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                if (widget.currentUser != null)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_rounded,
                                        size: 18,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${widget.currentUser!.followersCount} followers · ${widget.currentUser!.publicGenerationsCount} posts',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: textSecondary),
                                      ),
                                    ],
                                  )
                                else
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_rounded,
                                        size: 18,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Loading...',
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
                            onPressed: widget.onToggleTheme,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  // Feed list
                  if (_artworks.isEmpty && !_isLoadingFeed)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No artworks in your feed yet',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Follow more users to see their artworks',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: AnimationLimiter(
                        child: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              if (index >= _artworks.length) {
                                return _isLoadingFeed
                                    ? const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox();
                              }

                              final artwork = _artworks[index];
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 400),
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 20,
                                      ),
                                      child: _FeedCard(
                                        artwork: artwork,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        onTapAuthor: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProfileInspectScreen(
                                                    userId: artwork.user.id,
                                                    initialUser: artwork.user,
                                                  ),
                                            ),
                                          );
                                        },
                                        onTapCard: () {
                                          Navigator.of(context).push(
                                            PostDetailScreen.route(
                                              PostDetailScreen(
                                                author: artwork.user.name,
                                                avatarEmoji:
                                                    artwork.user.avatarUrl ??
                                                    '🎨',
                                                quote:
                                                    artwork.description ?? '',
                                                imageUrl: artwork.imageUrl,
                                                imageColor: Colors.purple,
                                                likes: artwork.likesCount,
                                                comments: artwork.commentsCount,
                                                time: _formatTime(
                                                  artwork.createdAt,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        onTapFollow: () async {
                                          await _toggleFollow(
                                            artwork.user.id,
                                            index,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount:
                                _artworks.length + (_isLoadingFeed ? 1 : 0),
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _FeedCard extends StatefulWidget {
  const _FeedCard({
    required this.artwork,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTapAuthor,
    required this.onTapCard,
    required this.onTapFollow,
  });

  final ArtworkModel artwork;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTapAuthor;
  final VoidCallback onTapCard;
  final VoidCallback onTapFollow;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.artwork.isLikedByMe;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = context.cardBackgroundColor;
    final border = context.borderColor;

    return GestureDetector(
      onTap: widget.onTapCard,
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
              // Author row with follow button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onTapAuthor,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: widget.artwork.user.avatarUrl != null
                            ? NetworkImage(widget.artwork.user.avatarUrl!)
                            : null,
                        backgroundColor: AppColors.primaryPurple.withOpacity(
                          0.3,
                        ),
                        child: widget.artwork.user.avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onTapAuthor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.artwork.user.name,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: widget.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (widget.artwork.user.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: Colors.blue,
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              _formatTime(widget.artwork.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: widget.textSecondary,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: widget.onTapFollow,
                      tooltip: 'Follow user',
                    ),
                  ],
                ),
              ),
              // AI-generated image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.grey[300],
                  child: CachedNetworkImage(
                    imageUrl: widget.artwork.imageUrl,
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
                        Icons.broken_image,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ),
              // Title (if exists)
              if (widget.artwork.title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    widget.artwork.title!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: widget.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Description
              if (widget.artwork.description != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    widget.artwork.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              // Actions: like, comment, share
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
                child: Row(
                  children: [
                    _ActionChip(
                      icon: _isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      label: '${widget.artwork.likesCount}',
                      color: _isLiked
                          ? AppColors.accentPink
                          : widget.textSecondary,
                      onTap: () {
                        setState(() => _isLiked = !_isLiked);
                      },
                    ),
                    const SizedBox(width: 16),
                    _ActionChip(
                      icon: Icons.chat_bubble_rounded,
                      label: '${widget.artwork.commentsCount}',
                      color: AppColors.primaryBlue,
                      onTap: () {},
                    ),
                    const Spacer(),
                    _ActionChip(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      color: widget.textSecondary,
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
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
