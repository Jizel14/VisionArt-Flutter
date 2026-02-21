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
    } catch (_) {
      setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _toggleFollow(String userId) async {
    try {
      await _followService.followUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Followed successfully'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Welcome, ${widget.userName}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_artworks.isEmpty && !_isLoadingFeed)
                    SliverToBoxAdapter(
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
                              style: TextStyle(color: textSecondary),
                            ),
                          ],
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
                                          child:
                                              CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox();
                              }

                              final artwork = _artworks[index];

                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration:
                                    const Duration(milliseconds: 400),
                                child: SlideAnimation(
                                  verticalOffset: 30,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 20),
                                      child: _FeedCard(
                                        artwork: artwork,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                        onTapAuthor: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProfileInspectScreen(
                                                userId: artwork.user.id,
                                                initialUser: artwork.user,
                                              ),
                                            ),
                                          );
                                        },
                                        onTapCard: () {
                                          Navigator.push(
                                            context,
                                            PostDetailScreen.route(
                                              PostDetailScreen(
                                                author: artwork.user.name,
                                                avatarEmoji:
                                                    artwork.user.avatarUrl ??
                                                        '🎨',
                                                quote:
                                                    artwork.description ?? '',
                                                imageUrl:
                                                    artwork.imageUrl,
                                                imageColor:
                                                    Colors.purple,
                                                likes:
                                                    artwork.likesCount,
                                                comments:
                                                    artwork.commentsCount,
                                                time: _formatTime(
                                                    artwork.createdAt),
                                              ),
                                            ),
                                          );
                                        },
                                        onTapFollow: () =>
                                            _toggleFollow(
                                                artwork.user.id),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount:
                                _artworks.length +
                                    (_isLoadingFeed ? 1 : 0),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                      child: SizedBox(height: 100)),
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
      child: Shimmer.fromColors(
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
    );
  }

  String _formatTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
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
    return GestureDetector(
      onTap: widget.onTapCard,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onTapAuthor,
                  child: CircleAvatar(
                    backgroundImage:
                        widget.artwork.user.avatarUrl != null
                            ? NetworkImage(
                                widget.artwork.user.avatarUrl!)
                            : null,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: widget.onTapFollow,
                ),
              ],
            ),
            const SizedBox(height: 12),
            CachedNetworkImage(
              imageUrl: widget.artwork.imageUrl,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}