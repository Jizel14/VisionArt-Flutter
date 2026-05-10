import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

/// Post detail: image, quote, author, and comments with show more / show less.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.author,
    required this.avatarEmoji,
    required this.quote,
    this.imageUrl,
    required this.imageColor,
    required this.likes,
    required this.comments,
    required this.time,
  });

  final String author;
  final String avatarEmoji;
  final String quote;
  final String? imageUrl;
  final Color imageColor;
  final int likes;
  final int comments;
  final String time;

  static PageRouteBuilder route(PostDetailScreen screen) {
    return PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => screen,
      transitionsBuilder: (_, animation, __, child) {
        final fade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        );
        final slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  static const int _commentsPreview = 3;
  bool _showAllComments = false;

  static List<Map<String, String>> _mockCommentsFor(String author) {
    return [
      {'user': 'Maya', 'text': 'This is stunning! Love the vibe.'},
      {'user': 'Leo', 'text': 'The colors are so rich. What prompt did you use?'},
      {'user': 'Zoe', 'text': 'Adding to my inspiration board 💜'},
      {'user': 'Alex', 'text': 'Would love to see more in this style.'},
      {'user': 'Sam', 'text': 'Beautiful work. Following!'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final cardBg = context.cardBackgroundColor;
    final commentsList = _mockCommentsFor(widget.author);
    final displayed = _showAllComments ? commentsList : commentsList.take(_commentsPreview).toList();
    final hasMore = commentsList.length > _commentsPreview;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              child: Container(
                                height: 220,
                                width: double.infinity,
                                color: widget.imageColor,
                                child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: widget.imageUrl!,
                                        fit: BoxFit.cover,
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
                            Positioned(
                              top: 12,
                              right: 12,
                              child: IconButton.filled(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black38,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          AppColors.primaryPurple.withOpacity(0.3),
                                      child: Text(widget.avatarEmoji,
                                          style: const TextStyle(fontSize: 18)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.author,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: textPrimary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            widget.time,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '"${widget.quote}"',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: textPrimary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Icon(Icons.favorite_rounded,
                                        size: 20, color: AppColors.accentPink),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.likes} likes',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: textSecondary),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.chat_bubble_rounded,
                                        size: 20, color: AppColors.primaryBlue),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${widget.comments} comments',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Comments',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ...displayed.map((c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor:
                                                AppColors.primaryPurple.withOpacity(0.25),
                                            child: Text(
                                              (c['user'] ?? '?')[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  c['user']!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color: textPrimary,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  c['text']!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(color: textSecondary),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                if (hasMore)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() => _showAllComments = !_showAllComments);
                                      },
                                      icon: Icon(
                                        _showAllComments
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        size: 20,
                                        color: AppColors.primaryBlue,
                                      ),
                                      label: Text(
                                        _showAllComments
                                            ? 'Show less comments'
                                            : 'Show more comments',
                                        style: TextStyle(
                                          color: AppColors.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
    );
  }
}
