import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:url_launcher/url_launcher.dart';


import '../../../core/models/artwork_model.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/visioncraft_service.dart';
import '../../../core/web_download.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import 'similar_artworks_screen.dart';
import 'generate_video_screen.dart';
import '../../widgets/video_player_widget.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.userId});

  final String userId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

// ─── Smart Search Engine ──────────────────────────────────────────────────────
// Search is now handled dynamically from the backend using Gemini for 
// semantic expansion and intelligent keyword matching.
// This allows the gallery to find images based on deep visual details
// extracted from the generation prompts.
// ─────────────────────────────────────────────────────────────────────────────

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

  // ── Search state ─────────────────────────────────────────────────────────
  bool _searchOpen = false;
  String _searchQuery = '';
  String _lastProcessedQuery = ''; // To prevent race conditions
  _QuickFilter _activeFilter = _QuickFilter.none;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;

  List<ArtworkModel> get _filteredArtworks {
    // The backend now handles all intelligent filtering and searching.
    // We simply return the results as they were fetched from the server.
    return List<ArtworkModel>.from(_artworks);
  }

  bool get _isSearchActive =>
      _searchQuery.trim().isNotEmpty || _activeFilter != _QuickFilter.none;

  @override
  void initState() {
    super.initState();
    _loadGallery();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(GalleryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we finally got a userId (e.g. after profile loaded), trigger the load
    if (widget.userId.isNotEmpty && oldWidget.userId.isEmpty) {
      _loadGallery();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadGallery({bool refresh = true}) async {
    // Prevent loading if userId is not yet available
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
        // If query has changed while we were waiting, ignore these results
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



  void _showArtworkDetails(BuildContext context, ArtworkModel artwork, int index) {
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

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchQuery = '';
        _searchController.clear();
        _activeFilter = _QuickFilter.none;
        _searchFocus.unfocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeColors.surfaceColor(context),
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: SizeTransition(sizeFactor: anim, axis: Axis.horizontal, child: child)),
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
                  style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: !_searchOpen,
        actions: [
          if (!_searchOpen)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: AppColors.primaryPurple.withOpacity(0.7)),
              onPressed: () => _loadGallery(refresh: true),
              tooltip: 'Refresh gallery',
            ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: ValueKey(_searchOpen),
              icon: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: _searchOpen ? AppColors.accentPink : AppColors.primaryPurple,
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
                AppThemeColors.surfaceColor(context),
                AppThemeColors.surfaceColor(context).withOpacity(0.0),
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
                  color: AppThemeColors.textPrimaryColor(context),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      return _EmptyGalleryState();
    }

    final filtered = _filteredArtworks;

    return RefreshIndicator(
      onRefresh: _loadGallery,
      color: AppColors.primaryPurple,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Spacing for AppBar ─────────────────────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 96)),

          // ── Quick Filter Chips ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _searchOpen
                  ? _QuickFiltersRow(
                      activeFilter: _activeFilter,
                      onSelect: _setFilter,
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // ── Search result summary ──────────────────────────────────────────
          if (_isSearchActive)
            SliverToBoxAdapter(
              child: _SearchSummary(
                count: filtered.length,
                total: _artworks.length,
                query: _searchQuery,
                onClear: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _activeFilter = _QuickFilter.none;
                  });
                },
              ),
            ),

          // ── Empty search result ────────────────────────────────────────────
          if (_isSearchActive && filtered.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptySearchState(),
            )
          else
            // ── Gallery Grid ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filtered.length) {
                      return const _LoadingCard();
                    }
                    final artwork = filtered[index];
                    final realIndex = _artworks.indexOf(artwork);
                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: Duration(milliseconds: (index % 6) * 60),
                      child: GestureDetector(
                        onTap: () => _showArtworkDetails(
                          context,
                          artwork,
                          realIndex >= 0 ? realIndex : index,
                        ),
                        child: _GalleryItem(
                          artwork: artwork,
                          highlight: _searchQuery.trim().isEmpty
                              ? null
                              : _searchQuery.trim(),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length + (_loadingMore ? 2 : 0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryItem extends StatelessWidget {
  const _GalleryItem({required this.artwork, this.highlight});

  final ArtworkModel artwork;
  final String? highlight; // search query for glow effect

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (artwork.imageUrl.startsWith('data:image')) {
      final base64Str = artwork.imageUrl.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Str));
    } else if (artwork.imageUrl.startsWith('http')) {
      imageProvider = NetworkImage(artwork.imageUrl);
    }

    // Show a purple glow border when this card matches the active search.
    final bool isHighlighted =
        highlight != null && highlight!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppThemeColors.cardBackgroundColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (isHighlighted)
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.55),
              blurRadius: 18,
              spreadRadius: 2,
            ),
        ],
        border: Border.all(
          color: isHighlighted
              ? AppColors.primaryPurple.withOpacity(0.8)
              : AppThemeColors.borderColor(context).withOpacity(0.5),
          width: isHighlighted ? 1.5 : 0.5,
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
                // ── Like & Comment counts inline ─────────────
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      artwork.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                      size: 12,
                      color: artwork.isLikedByMe ? AppColors.accentPink : Colors.white70,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${artwork.likesCount}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text(
                      '${artwork.commentsCount}',
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Play Icon overlay for videos
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
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
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
                color: AppThemeColors.textPrimaryColor(context),
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
                  color: AppThemeColors.textSecondaryColor(context),
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
        color: AppThemeColors.borderColor(context).withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Search UI Widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Animated search text field shown inside the AppBar.
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
        color: AppThemeColors.textPrimaryColor(context),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Search style, prompt, artist…',
        hintStyle: TextStyle(
          color: AppThemeColors.textSecondaryColor(context).withOpacity(0.6),
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
        fillColor: AppThemeColors.cardBackgroundColor(context).withOpacity(0.8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide:
              BorderSide(color: AppColors.primaryPurple.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }
}

/// Horizontal scrollable row of quick-filter chips.
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
                  color: active
                      ? null
                      : AppThemeColors.cardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? Colors.transparent
                        : AppThemeColors.borderColor(context).withOpacity(0.5),
                  ),
                  boxShadow: active
                      ? AppColors.shadowSmall(AppColors.primaryPurple)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: active
                          ? Colors.white
                          : AppThemeColors.textSecondaryColor(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? Colors.white
                            : AppThemeColors.textSecondaryColor(context),
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

/// Shows "X of Y results" + clear button.
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
              foregroundColor: AppThemeColors.textSecondaryColor(context),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when search has no results.
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
                color: AppThemeColors.textPrimaryColor(context),
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
                  color: AppThemeColors.textSecondaryColor(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Artwork Details Bottom Sheet — with dynamic likes, comments, and
// "Explore Similar" moved to a dedicated screen via app bar button.
// ═══════════════════════════════════════════════════════════════════════════════

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

class _ArtworkDetailsBottomSheetState
    extends State<_ArtworkDetailsBottomSheet> with TickerProviderStateMixin {
  bool _isSaving = false;
  bool _isGeneratingVideo = false;
  final _visionCraft = VisionCraftService();
  final _artworkService = ArtworkService();

  // ── Like state ─────────────────────────────────────────────────────────
  late bool _isLiked;
  late int _likesCount;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;

  // ── Comments state ────────────────────────────────────────────────────
  final List<ArtworkCommentItem> _comments = [];
  bool _loadingComments = true;
  bool _postingComment = false;
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  bool _showComments = false;

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

    _loadComments();
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    // Optimistic update
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
        newCount = await _artworkService.likeArtwork(widget.artwork.id);
      } else {
        newCount = await _artworkService.unlikeArtwork(widget.artwork.id);
      }
      if (mounted) {
        setState(() {
          _likesCount = newCount;
        });
        // Notify parent to refresh the gallery item
        widget.onArtworkUpdated?.call(widget.artwork.copyWith(
          likesCount: newCount,
          isLikedByMe: _isLiked,
        ));
      }
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likesCount += _isLiked ? 1 : -1;
        });
      }
    }
  }

  Future<void> _loadComments() async {
    setState(() => _loadingComments = true);
    try {
      final comments = await _artworkService.getArtworkComments(widget.artwork.id);
      if (mounted) {
        setState(() {
          _comments.clear();
          _comments.addAll(comments);
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _postingComment) return;

    setState(() => _postingComment = true);
    try {
      final comment = await _artworkService.createArtworkComment(
        widget.artwork.id,
        text,
      );
      if (mounted) {
        setState(() {
          _comments.insert(0, comment);
          _commentController.clear();
          _postingComment = false;
        });
        // Update comment count on parent
        widget.onArtworkUpdated?.call(widget.artwork.copyWith(
          commentsCount: widget.artwork.commentsCount + 1,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _postingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          _buildSnackBar('❌ Could not post comment', success: false),
        );
      }
    }
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

  Future<void> _generateVideo() async {
    Navigator.of(context).pop(); // Close bottom sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenerateVideoScreen(
          artwork: widget.artwork,
          onVideoGenerated: (url) {
            if (mounted) {
              widget.onArtworkUpdated?.call(widget.artwork.copyWith(videoUrl: url));
            }
          },
        ),
      ),
    );
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

  // ── Helper: build an image provider for an ArtworkModel ────────────────
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
    final imageProvider = _imageProviderFor(widget.artwork);
    final screenHeight = MediaQuery.of(context).size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: screenHeight * 0.92,
      decoration: BoxDecoration(
        color: AppThemeColors.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Blurred background
          if (imageProvider != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: Image(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
          if (imageProvider != null)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: AppThemeColors.surfaceColor(context).withOpacity(0.85)),
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
                    // ── Drag Handle ──
                    Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppThemeColors.textSecondaryColor(context).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Spacer(),
                    // ── "Explore Similar" button ──
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop(); // Close bottom sheet
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SimilarArtworksScreen(artwork: widget.artwork),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          height: 350, // Fixed height for consistency
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
                              ? VideoPlayerWidget(videoUrl: widget.artwork.videoUrl!)
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

                      // ═══ Like & Comment Action Bar ═══════════════════════
                      _buildSocialActionBar(isDark),

                      const SizedBox(height: 20),

                      // ═══ Generation Details Card ═══════════════════════════
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppThemeColors.borderColor(context).withOpacity(0.3),
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
                                    color: AppColors.primaryPurple.withOpacity(0.2),
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
                              widget.artwork.description ?? 'No prompt provided.',
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: AppThemeColors.textPrimaryColor(context).withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Divider(color: AppThemeColors.borderColor(context).withOpacity(0.5)),
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
                      const SizedBox(height: 24),

                      // ═══ Comments Section ══════════════════════════════════
                      _buildCommentsSection(isDark),

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
                // 1. Generate Video Button
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppThemeColors.borderColor(context).withOpacity(0.5)),
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
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.movie_creation_rounded, size: 20),
                                      SizedBox(width: 8),
                                      Text('Video', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 2. Save Button
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
                                const Icon(Icons.download_rounded, color: Colors.white, size: 20),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // Social Action Bar (Like + Comment toggle)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSocialActionBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemeColors.borderColor(context).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // ── Like Button ──────────────────────────────────
          GestureDetector(
            onTap: _toggleLike,
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _heartScaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _heartScaleAnimation.value,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(_isLiked),
                          color: _isLiked ? AppColors.accentPink : AppThemeColors.textSecondaryColor(context),
                          size: 26,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    '$_likesCount',
                    key: ValueKey(_likesCount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _isLiked
                          ? AppColors.accentPink
                          : AppThemeColors.textPrimaryColor(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _likesCount == 1 ? 'like' : 'likes',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppThemeColors.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Comment Toggle Button ───────────────────────
          GestureDetector(
            onTap: () => setState(() => _showComments = !_showComments),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _showComments
                    ? AppColors.primaryBlue.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    _showComments
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 22,
                    color: _showComments
                        ? AppColors.primaryBlue
                        : AppThemeColors.textSecondaryColor(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_comments.length}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _showComments
                          ? AppColors.primaryBlue
                          : AppThemeColors.textPrimaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Comments Section (expandable)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCommentsSection(bool isDark) {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: _buildCommentsContent(isDark),
      crossFadeState:
          _showComments ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 300),
      sizeCurve: Curves.easeInOut,
    );
  }

  Widget _buildCommentsContent(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppThemeColors.borderColor(context).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.2),
                        AppColors.primaryPurple.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.forum_rounded,
                      size: 18, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                if (_loadingComments)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryPurple.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Comment Input ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppThemeColors.borderColor(context).withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppThemeColors.textPrimaryColor(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts...',
                        hintStyle: TextStyle(
                          color: AppThemeColors.textSecondaryColor(context).withOpacity(0.6),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _postingComment ? null : _postComment,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _postingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Comments List ──────────────────────────────────
          if (_loadingComments)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 40,
                        color: AppThemeColors.textSecondaryColor(context).withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text(
                      'No comments yet',
                      style: TextStyle(
                        color: AppThemeColors.textSecondaryColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to share your thoughts!',
                      style: TextStyle(
                        color: AppThemeColors.textSecondaryColor(context).withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: _comments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  delay: Duration(milliseconds: index * 60),
                  child: _CommentBubble(comment: _comments[index]),
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Comment Bubble Widget
// ═══════════════════════════════════════════════════════════════════════════════
class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.comment});

  final ArtworkCommentItem comment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withOpacity(0.7),
                  AppColors.primaryBlue.withOpacity(0.7),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.userName.isNotEmpty
                    ? comment.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.03),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: AppThemeColors.borderColor(context).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppThemeColors.textPrimaryColor(context),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(comment.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppThemeColors.textSecondaryColor(context).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppThemeColors.textPrimaryColor(context).withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
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
            color: AppThemeColors.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppThemeColors.textPrimaryColor(context),
          ),
        ),
      ],
    );
  }
}
