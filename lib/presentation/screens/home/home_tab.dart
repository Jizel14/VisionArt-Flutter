import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api_client.dart';
import '../../../core/error_utils.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/notifications_service.dart';
import '../../../core/models/artwork_model.dart';
import '../../../core/models/user_model.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';
import 'notifications_screen.dart';
import '../profile/artwork_detail_screen.dart';
import 'saved_collections_screen.dart';
import '../profile/profile_inspect_screen.dart';
import '../../widgets/admin_announcement_banner.dart';

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
  late NotificationsService _notificationsService;
  late ScrollController _scrollController;

  List<ArtworkModel> _artworks = [];
  bool _isLoadingFeed = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _artworkService = ArtworkService();
    _followService = FollowService();
    _notificationsService = NotificationsService();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadFeed();
    _loadUnreadNotifications();
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

  Future<void> _refreshFeed() async {
    setState(() {
      _artworks = [];
      _currentPage = 1;
      _hasMore = true;
    });
    await _loadFeed();
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final count = await _notificationsService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadNotificationsCount = count);
    } catch (_) {}
  }

  Future<void> _openNotifications() async {
    final selectedArtworkId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );

    if (!mounted) return;

    if (selectedArtworkId != null && selectedArtworkId.isNotEmpty) {
      await _openCommentsForArtworkId(selectedArtworkId);
    }

    _loadUnreadNotifications();
  }

  Future<void> _openCommentsForArtworkId(String artworkId) async {
    final existingIndex = _artworks.indexWhere((item) => item.id == artworkId);
    if (existingIndex >= 0) {
      await _openComments(existingIndex);
      return;
    }

    try {
      final artwork = await _artworkService.getArtwork(artworkId);
      if (!mounted) return;

      setState(() {
        _artworks.insert(0, artwork);
      });

      await _openComments(0);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open artwork comments.')),
      );
    }
  }

  Future<void> _openSavedCollections() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedCollectionsScreen()),
    );
    _refreshFeed();
  }

  Future<void> _toggleFollow(int artworkIndex) async {
    final artwork = _artworks[artworkIndex];
    final userId = artwork.user.id;
    final isCurrentlyFollowing = artwork.isFollowedByMe;

    try {
      if (isCurrentlyFollowing) {
        await _followService.unfollowUser(userId);
      } else {
        await _followService.followUser(userId);
      }

      if (mounted) {
        // Update the follow status for ALL artworks from this user in the feed
        setState(() {
          _artworks = _artworks.map((a) {
            if (a.user.id == userId) {
              return a.copyWith(isFollowedByMe: !isCurrentlyFollowing);
            }
            return a;
          }).toList();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyFollowing
                  ? 'Unfollowed successfully'
                  : 'Followed successfully',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _toggleLike(int artworkIndex) async {
    final artwork = _artworks[artworkIndex];
    final wasLiked = artwork.isLikedByMe;
    final optimisticLikes = wasLiked
        ? (artwork.likesCount > 0 ? artwork.likesCount - 1 : 0)
        : artwork.likesCount + 1;

    setState(() {
      _artworks[artworkIndex] = artwork.copyWith(
        isLikedByMe: !wasLiked,
        likesCount: optimisticLikes,
      );
    });

    try {
      final updatedLikesCount = wasLiked
          ? await _artworkService.unlikeArtwork(artwork.id)
          : await _artworkService.likeArtwork(artwork.id);

      if (!mounted) return;
      setState(() {
        final updatedArtwork = _artworks[artworkIndex];
        _artworks[artworkIndex] = updatedArtwork.copyWith(
          likesCount: updatedLikesCount,
          isLikedByMe: !wasLiked,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _artworks[artworkIndex] = artwork;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like. Please retry.')),
      );
    }
  }

  Future<void> _toggleSave(int artworkIndex) async {
    final artwork = _artworks[artworkIndex];
    final wasSaved = artwork.isSavedByMe;

    setState(() {
      _artworks[artworkIndex] = artwork.copyWith(isSavedByMe: !wasSaved);
    });

    try {
      if (wasSaved) {
        await _artworkService.unsaveArtwork(artwork.id);
      } else {
        await _artworkService.saveArtwork(
          artwork.id,
          collectionName: 'Favorites',
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _artworks[artworkIndex] = artwork;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasSaved ? 'Failed to remove from saved' : 'Failed to save artwork',
          ),
        ),
      );
    }
  }

  Future<void> _openComments(int artworkIndex) async {
    final artwork = _artworks[artworkIndex];
    final TextEditingController commentCtrl = TextEditingController();
    final List<ArtworkCommentItem> comments = [];
    bool isLoadingComments = true;
    bool isSubmitting = false;
    bool isLoadingMentionSuggestions = false;
    bool hasRequestedComments = false;
    bool isSheetOpen = true;
    ArtworkCommentItem? replyingTo;
    String? commentErrorMessage;
    List<MentionUserItem> mentionSuggestions = const <MentionUserItem>[];
    final Map<String, String> selectedMentionIdsByName = {};
    final commentScrollController = ScrollController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        Future<void> loadMentionSuggestions(
          String input,
          StateSetter setSheetState,
        ) async {
          final mentionToken = _extractMentionToken(input);
          if (mentionToken == null || mentionToken.length < 2) {
            if (!mounted || !isSheetOpen || !sheetContext.mounted) return;
            setSheetState(() {
              mentionSuggestions = const <MentionUserItem>[];
              isLoadingMentionSuggestions = false;
            });
            return;
          }

          setSheetState(() => isLoadingMentionSuggestions = true);
          try {
            final users = await _artworkService.searchMentionUsers(
              mentionToken,
            );
            if (!mounted || !isSheetOpen || !sheetContext.mounted) return;
            setSheetState(() {
              mentionSuggestions = users;
              isLoadingMentionSuggestions = false;
            });
          } catch (_) {
            if (!mounted || !isSheetOpen || !sheetContext.mounted) return;
            setSheetState(() {
              mentionSuggestions = const <MentionUserItem>[];
              isLoadingMentionSuggestions = false;
            });
          }
        }

        void selectMention(MentionUserItem user, StateSetter setSheetState) {
          final cursor = commentCtrl.selection.baseOffset;
          final currentText = commentCtrl.text;
          final safeCursor = cursor < 0 ? currentText.length : cursor;

          final textBeforeCursor = currentText.substring(0, safeCursor);
          final mentionStart = textBeforeCursor.lastIndexOf('@');

          String nextText;
          int nextCursor;

          if (mentionStart >= 0) {
            nextText =
                '${currentText.substring(0, mentionStart)}@${user.name} ${currentText.substring(safeCursor)}';
            nextCursor = mentionStart + user.name.length + 2;
          } else {
            nextText = '$currentText@${user.name} ';
            nextCursor = nextText.length;
          }

          commentCtrl.value = TextEditingValue(
            text: nextText,
            selection: TextSelection.collapsed(offset: nextCursor),
          );

          setSheetState(() {
            selectedMentionIdsByName[user.name.toLowerCase()] = user.id;
            mentionSuggestions = const <MentionUserItem>[];
            isLoadingMentionSuggestions = false;
          });
        }

        List<String> resolveMentionedUserIds(String content) {
          final lower = content.toLowerCase();
          final ids = selectedMentionIdsByName.entries
              .where((entry) => lower.contains('@${entry.key}'))
              .map((entry) => entry.value)
              .toSet()
              .toList();
          return ids;
        }

        ArtworkCommentItem appendReply(
          ArtworkCommentItem parent,
          ArtworkCommentItem reply,
        ) {
          return ArtworkCommentItem(
            id: parent.id,
            userId: parent.userId,
            userName: parent.userName,
            userAvatarUrl: parent.userAvatarUrl,
            content: parent.content,
            createdAt: parent.createdAt,
            parentCommentId: parent.parentCommentId,
            isEdited: parent.isEdited,
            replies: [...parent.replies, reply],
          );
        }

        Future<void> loadComments(StateSetter setSheetState) async {
          try {
            final fetched = await _artworkService.getArtworkComments(
              artwork.id,
            );
            if (!mounted || !isSheetOpen || !sheetContext.mounted) return;
            setSheetState(() {
              comments
                ..clear()
                ..addAll(fetched);
              isLoadingComments = false;
            });
          } catch (_) {
            if (!mounted || !isSheetOpen || !sheetContext.mounted) return;
            setSheetState(() => isLoadingComments = false);
          }
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (isLoadingComments &&
                comments.isEmpty &&
                !hasRequestedComments) {
              hasRequestedComments = true;
              loadComments(setSheetState);
            }

            final mediaQuery = MediaQuery.of(context);
            final keyboardOpen = mediaQuery.viewInsets.bottom > 0;
            final commentsMaxHeight =
                (mediaQuery.size.height * (keyboardOpen ? 0.28 : 0.42))
                    .clamp(170.0, 320.0)
                    .toDouble();
            final mentionMaxHeight = keyboardOpen ? 110.0 : 150.0;

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: commentScrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: mediaQuery.viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: context.borderColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 170,
                        maxHeight: commentsMaxHeight,
                      ),
                      child: isLoadingComments
                          ? const Center(child: CircularProgressIndicator())
                          : comments.isEmpty
                          ? Center(
                              child: Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: comments.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 16),
                              itemBuilder: (_, index) {
                                final comment = comments[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundImage:
                                              comment.userAvatarUrl != null
                                              ? NetworkImage(
                                                  comment.userAvatarUrl!,
                                                )
                                              : null,
                                          child: comment.userAvatarUrl == null
                                              ? Text(
                                                  comment.userName.isNotEmpty
                                                      ? comment.userName[0]
                                                            .toUpperCase()
                                                      : '?',
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comment.userName,
                                                style: TextStyle(
                                                  color: context
                                                      .textPrimaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                comment.content,
                                                style: TextStyle(
                                                  color: context
                                                      .textSecondaryColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              GestureDetector(
                                                onTap: () {
                                                  setSheetState(() {
                                                    replyingTo = comment;
                                                    commentCtrl.text =
                                                        '@${comment.userName} ';
                                                    commentCtrl.selection =
                                                        TextSelection.collapsed(
                                                          offset: commentCtrl
                                                              .text
                                                              .length,
                                                        );
                                                    selectedMentionIdsByName[comment
                                                            .userName
                                                            .toLowerCase()] =
                                                        comment.userId;
                                                  });
                                                },
                                                child: Text(
                                                  'Reply',
                                                  style: TextStyle(
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (comment.replies.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 24,
                                        ),
                                        child: Column(
                                          children: comment.replies.map((reply) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 12,
                                                    backgroundImage:
                                                        reply.userAvatarUrl !=
                                                            null
                                                        ? NetworkImage(
                                                            reply.userAvatarUrl!,
                                                          )
                                                        : null,
                                                    child:
                                                        reply.userAvatarUrl ==
                                                            null
                                                        ? Text(
                                                            reply
                                                                    .userName
                                                                    .isNotEmpty
                                                                ? reply
                                                                      .userName[0]
                                                                      .toUpperCase()
                                                                : '?',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 11,
                                                                ),
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          reply.userName,
                                                          style: TextStyle(
                                                            color: context
                                                                .textPrimaryColor,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          reply.content,
                                                          style: TextStyle(
                                                            color: context
                                                                .textSecondaryColor,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    if (replyingTo != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaceColor.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Replying to ${replyingTo!.userName}',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  replyingTo = null;
                                });
                              },
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isLoadingMentionSuggestions)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    else if (mentionSuggestions.isNotEmpty)
                      Container(
                        constraints: BoxConstraints(maxHeight: mentionMaxHeight),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceColor.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.borderColor.withOpacity(0.4),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: mentionSuggestions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: context.borderColor.withOpacity(0.3),
                          ),
                          itemBuilder: (_, index) {
                            final user = mentionSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 12,
                                backgroundImage: user.avatarUrl != null
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        user.name.isNotEmpty
                                            ? user.name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(fontSize: 11),
                                      )
                                    : null,
                              ),
                              title: Text(
                                user.name,
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 13,
                                ),
                              ),
                              onTap: () => selectMention(user, setSheetState),
                            );
                          },
                        ),
                      ),
                    if (commentErrorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error.withOpacity(
                            0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error.withOpacity(
                              0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1, right: 8),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                commentErrorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentCtrl,
                            onChanged: (value) {
                              if (commentErrorMessage != null) {
                                setSheetState(() => commentErrorMessage = null);
                              }
                              loadMentionSuggestions(value, setSheetState);
                            },
                            style: TextStyle(color: context.textPrimaryColor),
                            decoration: InputDecoration(
                              hintText: replyingTo != null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                              hintStyle: TextStyle(
                                color: context.textSecondaryColor,
                              ),
                              filled: true,
                              fillColor: context.surfaceColor.withOpacity(0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final content = commentCtrl.text.trim();
                                  if (content.isEmpty) return;

                                  final mentionUserIds = resolveMentionedUserIds(
                                    content,
                                  );

                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    final created = await _artworkService
                                        .createArtworkComment(
                                          artwork.id,
                                          content,
                                          parentCommentId: replyingTo?.id,
                                          mentionedUserIds: mentionUserIds,
                                        );

                                    if (!mounted ||
                                        !isSheetOpen ||
                                        !sheetContext.mounted)
                                      return;
                                    setSheetState(() {
                                      commentErrorMessage = null;
                                      if (created.parentCommentId != null) {
                                        final parentIndex = comments.indexWhere(
                                          (item) =>
                                              item.id == created.parentCommentId,
                                        );
                                        if (parentIndex >= 0) {
                                          comments[parentIndex] = appendReply(
                                            comments[parentIndex],
                                            created,
                                          );
                                        } else {
                                          comments.insert(0, created);
                                        }
                                      } else {
                                        comments.insert(0, created);
                                      }
                                      commentCtrl.clear();
                                      replyingTo = null;
                                      mentionSuggestions =
                                          const <MentionUserItem>[];
                                      isSubmitting = false;
                                    });

                                    setState(() {
                                      final current = _artworks[artworkIndex];
                                      _artworks[artworkIndex] = current.copyWith(
                                        commentsCount:
                                            current.commentsCount + 1,
                                      );
                                    });
                                  } on ApiException catch (e) {
                                    if (!mounted ||
                                        !isSheetOpen ||
                                        !sheetContext.mounted)
                                      return;
                                    setSheetState(() {
                                      isSubmitting = false;
                                      commentErrorMessage = e.message;
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (commentScrollController.hasClients) {
                                        commentScrollController.animateTo(
                                          commentScrollController
                                              .position.maxScrollExtent,
                                          duration:
                                              const Duration(milliseconds: 250),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  } catch (e) {
                                    if (!mounted ||
                                        !isSheetOpen ||
                                        !sheetContext.mounted)
                                      return;
                                    setSheetState(() {
                                      isSubmitting = false;
                                      commentErrorMessage =
                                          userFacingApiError(e);
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (commentScrollController.hasClients) {
                                        commentScrollController.animateTo(
                                          commentScrollController
                                              .position.maxScrollExtent,
                                          duration:
                                              const Duration(milliseconds: 250),
                                          curve: Curves.easeOut,
                                        );
                                      }
                                    });
                                  }
                                },
                          icon: isSubmitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      isSheetOpen = false;
      commentCtrl.dispose();
      commentScrollController.dispose();
    });
  }

  String? _extractMentionToken(String text) {
    if (text.isEmpty) return null;

    final match = RegExp(r'@([A-Za-z0-9._-]{1,64})$').firstMatch(text);
    return match?.group(1);
  }

  Future<void> _openReport(int artworkIndex) async {
    final artwork = _artworks[artworkIndex];
    final TextEditingController detailsCtrl = TextEditingController();
    String selectedReason = ArtworkService.reportReasons.first;
    bool isSubmitting = false;
    bool isSheetOpen = true;
    String? reportErrorMessage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Artwork',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.textPrimaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: context.surfaceColor.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: ArtworkService.reportReasons
                        .map(
                          (reason) => DropdownMenuItem<String>(
                            value: reason,
                            child: Text(reason),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => selectedReason = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: detailsCtrl,
                    minLines: 3,
                    maxLines: 4,
                    style: TextStyle(color: context.textPrimaryColor),
                    decoration: InputDecoration(
                      hintText: 'Optional details...',
                      hintStyle: TextStyle(color: context.textSecondaryColor),
                      filled: true,
                      fillColor: context.surfaceColor.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (reportErrorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(
                              0.12,
                            ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(
                                0.35,
                              ),
                        ),
                      ),
                      child: Text(
                        reportErrorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() {
                                isSubmitting = true;
                                reportErrorMessage = null;
                              });
                              try {
                                await _artworkService.reportArtwork(
                                  artworkId: artwork.id,
                                  reason: selectedReason,
                                  details: detailsCtrl.text.trim(),
                                );

                                if (!mounted ||
                                    !isSheetOpen ||
                                    !sheetContext.mounted)
                                  return;
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Artwork reported successfully.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted ||
                                    !isSheetOpen ||
                                    !sheetContext.mounted)
                                  return;
                                setSheetState(() {
                                  isSubmitting = false;
                                  reportErrorMessage = userFacingApiError(e);
                                });
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit report'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      isSheetOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return SmokeBackground(
      child: Column(
        children: [
          const AdminAnnouncementBanner(),
          Expanded(
            child: SafeArea(
              top: false,
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
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: _openSavedCollections,
                            icon: Icon(
                              Icons.bookmark_rounded,
                              color: textPrimary,
                            ),
                          ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton(
                                onPressed: _openNotifications,
                                icon: Icon(
                                  Icons.notifications_rounded,
                                  color: textPrimary,
                                ),
                              ),
                              if (_unreadNotificationsCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _unreadNotificationsCount > 99
                                          ? '99+'
                                          : '$_unreadNotificationsCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
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
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox();
                              }

                              final artwork = _artworks[index];
                              final isOwnPost =
                                  widget.currentUser != null &&
                                  widget.currentUser!.id == artwork.user.id;

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
                                        isOwnPost: isOwnPost,
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
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ArtworkDetailScreen(
                                                    artwork: artwork,
                                                  ),
                                            ),
                                          );
                                        },
                                        onTapFollow: () => _toggleFollow(index),
                                        onTapLike: () => _toggleLike(index),
                                        onTapSave: () => _toggleSave(index),
                                        onTapComments: () =>
                                            _openComments(index),
                                        onTapReport: () => _openReport(index),
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
          ),
        ],
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
}

class _FeedCard extends StatefulWidget {
  const _FeedCard({
    required this.artwork,
    required this.isOwnPost,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTapAuthor,
    required this.onTapCard,
    required this.onTapFollow,
    required this.onTapLike,
    required this.onTapSave,
    required this.onTapComments,
    required this.onTapReport,
  });

  final ArtworkModel artwork;
  final bool isOwnPost;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTapAuthor;
  final VoidCallback onTapCard;
  final VoidCallback onTapFollow;
  final VoidCallback onTapLike;
  final VoidCallback onTapSave;
  final VoidCallback onTapComments;
  final VoidCallback onTapReport;

  @override
  State<_FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<_FeedCard> {
  @override
  Widget build(BuildContext context) {
    final isFollowing = widget.artwork.isFollowedByMe;
    final isLiked = widget.artwork.isLikedByMe;
    final isSaved = widget.artwork.isSavedByMe;

    return GestureDetector(
      onTap: widget.onTapCard,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onTapAuthor,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: widget.artwork.user.avatarUrl != null
                            ? NetworkImage(widget.artwork.user.avatarUrl!)
                            : null,
                        child: widget.artwork.user.avatarUrl == null
                            ? Text(
                                widget.artwork.user.name.isNotEmpty
                                    ? widget.artwork.user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.artwork.user.name,
                            style: TextStyle(
                              color: widget.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (widget.artwork.title != null &&
                              widget.artwork.title!.isNotEmpty)
                            Text(
                              widget.artwork.title!,
                              style: TextStyle(
                                color: widget.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (!widget.isOwnPost)
                  IconButton(
                    icon: Icon(
                      isFollowing
                          ? Icons.how_to_reg_rounded
                          : Icons.person_add_rounded,
                      color: isFollowing
                          ? Colors.greenAccent
                          : widget.textSecondary,
                    ),
                    tooltip: isFollowing ? 'Following' : 'Follow',
                    onPressed: widget.onTapFollow,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: 'artwork_image_${widget.artwork.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.artwork.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _FooterAction(
                  icon: isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _formatCompactCount(widget.artwork.likesCount),
                  color: isLiked ? Colors.pinkAccent : widget.textSecondary,
                  onTap: widget.onTapLike,
                ),
                const SizedBox(width: 12),
                _FooterAction(
                  icon: Icons.mode_comment_outlined,
                  label: _formatCompactCount(widget.artwork.commentsCount),
                  color: widget.textSecondary,
                  onTap: widget.onTapComments,
                ),
                const SizedBox(width: 12),
                _FooterAction(
                  icon: isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  label: isSaved ? 'Saved' : 'Save',
                  color: isSaved ? Colors.amberAccent : widget.textSecondary,
                  onTap: widget.onTapSave,
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onTapReport,
                  icon: Icon(Icons.flag_outlined, color: widget.textSecondary),
                  tooltip: 'Report',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompactCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$value';
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
