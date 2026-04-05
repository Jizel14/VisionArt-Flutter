import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/artwork_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/social_share_sheet.dart';
import 'profile_inspect_screen.dart';

class ArtworkDetailScreen extends StatefulWidget {
  final ArtworkModel artwork;

  const ArtworkDetailScreen({Key? key, required this.artwork})
    : super(key: key);

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  late bool _isLiked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.artwork.isLikedByMe;
    _likesCount = widget.artwork.likesCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
  }

  void _onShare() {
    final link = 'https://visionart.app/artworks/${widget.artwork.id}';
    final title = widget.artwork.title?.isNotEmpty == true
        ? widget.artwork.title!
        : 'Untitled artwork';
    final caption = '$title by @${widget.artwork.user.name}\n$link';

    showSocialShareSheet(
      context: context,
      link: link,
      caption: caption,
      subject: '$title – VisionArt',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Image Header
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _onShare,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'artwork_image_${widget.artwork.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.artwork.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return Container(
                      color: context.surfaceColor,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.artwork.title?.isNotEmpty == true
                        ? widget.artwork.title!
                        : 'Untitled',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Artist Profile
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileInspectScreen(
                            userId: widget.artwork.user.id,
                            initialUser: widget.artwork.user,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage:
                                widget.artwork.user.avatarUrl != null
                                ? NetworkImage(widget.artwork.user.avatarUrl!)
                                : null,
                            child: widget.artwork.user.avatarUrl == null
                                ? const Icon(Icons.person_rounded)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.artwork.user.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.artwork.user.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '@${widget.artwork.user.email.split('@')[0]}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Prompt / Description
                  if (widget.artwork.description != null &&
                      widget.artwork.description!.isNotEmpty) ...[
                    Text(
                      widget.artwork.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Likes', _likesCount, context),
                      _buildStatItem(
                        'Comments',
                        widget.artwork.commentsCount,
                        context,
                      ),
                      _buildStatItem(
                        'Remixes',
                        widget.artwork.remixCount,
                        context,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          label: 'Like',
                          isSelected: _isLiked,
                          onTap: _toggleLike,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Comment',
                          isSelected: false,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.repeat_rounded,
                          label: 'Remix',
                          isSelected: false,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Remix Info
                  if (widget.artwork.remixedFrom != null) ...[
                    _buildGlassCard(
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              color: AppColors.accentPink,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remixed from',
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.artwork.remixedFrom!.user.name,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Details
                  _buildGlassCard(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildMetadataRow(
                            'Created',
                            _formatDate(widget.artwork.createdAt),
                            context,
                          ),
                          _buildMetadataRow(
                            'Visibility',
                            widget.artwork.isPublic ? 'Public' : 'Private',
                            context,
                          ),
                          if (widget.artwork.isNSFW)
                            _buildMetadataRow(
                              'Content',
                              'Contains NSFW content',
                              context,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48), // Padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDark
                  ? AppColors.primaryBlue.withOpacity(0.2)
                  : context.borderColor.withOpacity(0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (isSelected) {
      bgColor = AppColors.accentPink.withOpacity(0.15);
      fgColor = AppColors.accentPink;
      borderColor = AppColors.accentPink.withOpacity(0.5);
    } else {
      bgColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.04);
      fgColor = context.textPrimaryColor;
      borderColor = context.borderColor.withOpacity(0.5);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
