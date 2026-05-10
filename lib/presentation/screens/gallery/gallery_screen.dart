import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../../../core/models/artwork_model.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/web_download.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import 'generate_video_screen.dart';
import 'similar_artworks_screen.dart';
import '../../widgets/video_player_widget.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.userId});

  final String userId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

enum _QuickFilter { none, liked, popular, recent, remixed, videos }

class _GalleryScreenState extends State<GalleryScreen> {
  final _artworkService = ArtworkService();
  final List<ArtworkModel> _artworks = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  final ScrollController _scrollController = ScrollController();

  // Search state
  bool _searchOpen = false;
  String _searchQuery = '';
  _QuickFilter _activeFilter = _QuickFilter.none;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadGallery();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadGallery({bool refresh = true}) async {
    if (widget.userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
      });
      return;
    }

    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }

    final currentQuery = _searchQuery;
    try {
      final res = await _artworkService.getUserGallery(
        userId: widget.userId,
        page: _page,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery : null,
        filter: _activeFilter == _QuickFilter.none ? null : _activeFilter.name,
      );

      if (mounted) {
        if (currentQuery != _searchQuery && refresh) return;

        setState(() {
          if (refresh) {
            _artworks.clear();
          }
          _artworks.addAll(res.data);
          _page = res.page;
          _totalPages = res.totalPages;
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_loadingMore || _page >= _totalPages) return;
    _page++;
    _loadGallery(refresh: false);
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _loadGallery(refresh: true);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchQuery = '';
        _searchController.clear();
        _activeFilter = _QuickFilter.none;
        _searchFocus.unfocus();
        _loadGallery(refresh: true);
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          _searchFocus.requestFocus();
        });
      }
    });
  }

  void _setFilter(_QuickFilter f) {
    setState(() {
      _activeFilter = _activeFilter == f ? _QuickFilter.none : f;
    });
    _loadGallery(refresh: true);
  }

  void _showArtworkDetails(
      BuildContext context, ArtworkModel artwork, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArtworkDetailsBottomSheet(
        artwork: artwork,
        onArtworkUpdated: (updated) {
          if (mounted) {
            setState(() {
              _artworks[index] = updated;
            });
          }
        },
      ),
    );
  }

  bool get _isSearchActive =>
      _searchQuery.trim().isNotEmpty || _activeFilter != _QuickFilter.none;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SizeTransition(
                  sizeFactor: anim, axis: Axis.horizontal, child: child)),
          child: _searchOpen
              ? _SearchBar(
                  key: const ValueKey('searchbar'),
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                )
              : const Text(
                  'My Masterpieces',
                  key: ValueKey('title'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: !_searchOpen,
        actions: [
          if (!_searchOpen)
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: AppColors.primaryPurple.withOpacity(0.7)),
              onPressed: () => _loadGallery(refresh: true),
              tooltip: 'Refresh gallery',
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: ValueKey(_searchOpen),
              icon: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: _searchOpen
                    ? AppColors.accentPink
                    : AppColors.primaryPurple,
              ),
              onPressed: _toggleSearch,
              tooltip: _searchOpen ? 'Close search' : 'Search artworks',
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                context.surfaceColor,
                context.surfaceColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _artworks.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    if (_error != null && _artworks.isEmpty) {
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
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text(
              'Couldn\'t load your gallery',
              style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadGallery,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_artworks.isEmpty) {
      return _isSearchActive ? const _EmptySearchState() : _EmptyGalleryState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadGallery(refresh: true),
      color: AppColors.primaryPurple,
      child: Column(
        children: [
          // Quick Filters Row
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 8),
              child: _QuickFiltersRow(
                activeFilter: _activeFilter,
                onSelect: _setFilter,
              ),
            ),
          // Search Summary
          if (_isSearchActive)
            _SearchSummary(
              count: _artworks.length,
              total: _artworks.length,
              query: _searchQuery,
              onClear: () {
                _searchController.clear();
                _onSearchChanged('');
                setState(() => _activeFilter = _QuickFilter.none);
              },
            ),
          // Gallery Grid
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16, _searchOpen ? 8 : 100, 16, 24),
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _artworks.length + (_loadingMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= _artworks.length) {
                  return const _LoadingCard();
                }

                final artwork = _artworks[index];
                return FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  delay: Duration(milliseconds: (index % 6) * 100),
                  child: GestureDetector(
                    onTap: () => _showArtworkDetails(context, artwork, index),
                    child: _GalleryItem(artwork: artwork),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryItem extends StatelessWidget {
  const _GalleryItem({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (artwork.imageUrl.startsWith('data:image')) {
      final base64Str = artwork.imageUrl.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Str));
    } else if (artwork.imageUrl.startsWith('http')) {
      imageProvider = NetworkImage(artwork.imageUrl);
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(
          color: context.borderColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'artwork_image_${artwork.id}',
            child: imageProvider != null
                ? Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  )
                : Container(color: AppColors.border),
          ),

          // Magical Bottom Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: const Alignment(0.0, 0.2), // Gradient ends halfway up
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // Video Indicator Badge (if video exists)
          if (artwork.videoUrl != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 16),
              ),
            ),

          // Date and Style Badge
          Positioned(
            top: 12,
            right: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 10, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(artwork.createdAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Art details preview at bottom
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
                  const SizedBox(height: 2),
                  Text(
                    artwork.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Like and Comment counts
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
                          : Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${artwork.likesCount}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${artwork.commentsCount}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)}';
  }

  String _monthName(int month) {
    const months = [
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
      'Dec'
    ];
    return months[month - 1];
  }
}

class _EmptyGalleryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeInUp(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: const Icon(
                Icons.collections_outlined,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your Gallery is Empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Let your imagination run wild. Generate new artworks to see them collected here.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: context.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// A stunning bottom sheet to view detailed artwork information
class _ArtworkDetailsBottomSheet extends StatefulWidget {
  const _ArtworkDetailsBottomSheet({
    required this.artwork,
    this.onArtworkUpdated,
  });

  final ArtworkModel artwork;
  final ValueChanged<ArtworkModel>? onArtworkUpdated;

  @override
  State<_ArtworkDetailsBottomSheet> createState() =>
      _ArtworkDetailsBottomSheetState();
}

class _ArtworkDetailsBottomSheetState extends State<_ArtworkDetailsBottomSheet>
    with TickerProviderStateMixin {
  bool _isSaving = false;
  bool _isGeneratingVideo = false;

  // Like state
  late bool _isLiked;
  late int _likesCount;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.artwork.isLikedByMe;
    _likesCount = widget.artwork.likesCount;

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _heartAnimController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final artworkService = ArtworkService();
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
      if (_isLiked) {
        _heartAnimController.forward(from: 0.0);
      }
    });

    try {
      int newCount;
      if (_isLiked) {
        newCount = await artworkService.likeArtwork(widget.artwork.id);
      } else {
        newCount = await artworkService.unlikeArtwork(widget.artwork.id);
      }
      if (mounted) {
        setState(() {
          _likesCount = newCount;
        });
        widget.onArtworkUpdated?.call(widget.artwork.copyWith(
          likesCount: newCount,
          isLikedByMe: _isLiked,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _generateVideo() async {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenerateVideoScreen(
          artwork: widget.artwork,
          onVideoGenerated: (url) {
            if (mounted) {
              widget.onArtworkUpdated
                  ?.call(widget.artwork.copyWith(videoUrl: url));
            }
          },
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      Uint8List? bytes;
      if (widget.artwork.imageUrl.startsWith('data:image')) {
        final base64Str = widget.artwork.imageUrl.split(',').last;
        bytes = base64Decode(base64Str);
      }

      if (bytes == null) {
        throw Exception("Cannot download URL imagery directly yet.");
      }

      if (kIsWeb) {
        downloadWebImage(bytes, 'visionart_${widget.artwork.id}.png');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar('✅ Download started!', success: true),
          );
        }
      } else {
        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: 'visionart_${widget.artwork.id}',
        );
        final saved = result['isSuccess'] == true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _buildSnackBar(
              saved ? '🎨 Saved to Gallery!' : '❌ Could not save. Try again.',
              success: saved,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('❌ Error saving image: $e', success: false),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  SnackBar _buildSnackBar(String msg, {required bool success}) {
    return SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (widget.artwork.imageUrl.startsWith('data:image')) {
      final base64Str = widget.artwork.imageUrl.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Str));
    } else if (widget.artwork.imageUrl.startsWith('http')) {
      imageProvider = NetworkImage(widget.artwork.imageUrl);
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Blurred background
          if (imageProvider != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2, // very subtle
                child: Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (imageProvider != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: context.surfaceColor.withOpacity(0.85)),
              ),
            ),

          Column(
            children: [
              // Top bar with drag handle and "Explore Similar" button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    // Drag Handle
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.textSecondaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    // "Explore Similar" button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SimilarArtworksScreen(
                                  artwork: widget.artwork),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryPurple.withOpacity(0.15),
                                AppColors.primaryBlue.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_mosaic_rounded,
                                  size: 16, color: AppColors.primaryBlue),
                              SizedBox(width: 6),
                              Text(
                                'Similar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The Main Content (Image or Video)
                      Hero(
                        tag: 'artwork_image_${widget.artwork.id}',
                        child: Container(
                          height: 350,
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
                          child: widget.artwork.videoUrl != null
                              ? VideoPlayerWidget(
                                  videoUrl: widget.artwork.videoUrl!)
                              : InteractiveViewer(
                                  child: imageProvider != null
                                      ? Image(
                                          image: imageProvider,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 300, color: AppColors.border),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Like & Comment Action Bar
                      _buildSocialActionBar(context),

                      const SizedBox(height: 20),

                      // Information Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: context.borderColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Generation Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.artwork.title ?? 'Custom Default',
                                    style: const TextStyle(
                                      color: AppColors.lightBlue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'PROMPT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.artwork.description ??
                                  'No prompt provided.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color:
                                    context.textPrimaryColor.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Divider(
                                color: context.borderColor.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _BuildStat(
                                  label: 'Created',
                                  value: _formatDate(widget.artwork.createdAt),
                                ),
                                _BuildStat(
                                  label: 'Resolution',
                                  value: 'High Quality',
                                ),
                                _BuildStat(
                                  label: 'Format',
                                  value: 'PNG/JPEG',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120), // Bottom padding for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Button Overlay
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Row(
              children: [
                // Generate Video Button
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? Colors.white12
                          : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: context.borderColor.withOpacity(0.5)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isGeneratingVideo ? null : _generateVideo,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: _isGeneratingVideo
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryBlue))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.movie_creation_rounded,
                                          size: 20),
                                      SizedBox(width: 8),
                                      Text('Video',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Save Button
                Expanded(
                  flex: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isSaving ? null : _saveImage,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              else ...[
                                const Icon(Icons.download_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildSocialActionBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Like Button
          GestureDetector(
            onTap: _toggleLike,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _heartScaleAnimation,
                    child: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked
                          ? AppColors.accentPink
                          : context.textSecondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$_likesCount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Comments count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: context.textSecondaryColor,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.artwork.commentsCount}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Video indicator if exists
          if (widget.artwork.videoUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_fill,
                      color: AppColors.primaryPurple, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Video',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BuildStat extends StatelessWidget {
  const _BuildStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: context.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

// Search Bar Widget
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      autofocus: true,
      style: TextStyle(
        color: context.textPrimaryColor,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search style, prompt, artist...',
        hintStyle: TextStyle(
          color: context.textSecondaryColor.withOpacity(0.6),
          fontSize: 14,
        ),
        helperText: 'Intelligent AI-powered search',
        helperStyle: TextStyle(
          color: AppColors.primaryPurple.withOpacity(0.5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.auto_awesome_rounded,
          color: AppColors.primaryPurple,
          size: 20,
        ),
        filled: true,
        fillColor: context.cardBackgroundColor.withOpacity(0.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
              color: AppColors.primaryPurple.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }
}

// Quick Filters Row Widget
class _QuickFiltersRow extends StatelessWidget {
  const _QuickFiltersRow({
    required this.activeFilter,
    required this.onSelect,
  });

  final _QuickFilter activeFilter;
  final ValueChanged<_QuickFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = [
      (_QuickFilter.liked, Icons.favorite_rounded, 'Liked'),
      (_QuickFilter.popular, Icons.local_fire_department_rounded, 'Popular'),
      (_QuickFilter.recent, Icons.schedule_rounded, 'Recent'),
      (_QuickFilter.remixed, Icons.auto_fix_high_rounded, 'Remixed'),
      (_QuickFilter.videos, Icons.play_circle_outline_rounded, 'Videos'),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: chips.map((chip) {
          final (filter, icon, label) = chip;
          final active = activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: active ? AppColors.primaryGradient : null,
                  color: active ? null : context.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : context.borderColor.withOpacity(0.5),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primaryPurple.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: active ? Colors.white : context.textSecondaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color:
                            active ? Colors.white : context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Search Summary Widget
class _SearchSummary extends StatelessWidget {
  const _SearchSummary({
    required this.count,
    required this.total,
    required this.query,
    required this.onClear,
  });

  final int count;
  final int total;
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final label = query.trim().isNotEmpty
        ? '$count result${count == 1 ? '' : 's'} for "${query.trim()}"'
        : '$count artwork${count == 1 ? '' : 's'} shown';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 14),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: context.textSecondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

// Empty Search State Widget
class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 52,
                color: AppColors.primaryPurple.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Artworks Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Try a different style, mood, or keyword — or clear filters to see all your art.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: context.textSecondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
