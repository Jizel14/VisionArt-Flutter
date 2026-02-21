import 'package:flutter/material.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/models/artwork_model.dart';
import 'artwork_detail_screen.dart';

class UserGalleryScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserGalleryScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserGalleryScreen> createState() => _UserGalleryScreenState();
}

class _UserGalleryScreenState extends State<UserGalleryScreen> {
  late ArtworkService _artworkService;
  late ScrollController _scrollController;

  List<ArtworkModel> _artworks = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _artworkService = ArtworkService();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadArtworks();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArtworks() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final result = await _artworkService.getUserGallery(
        userId: widget.userId,
        page: _currentPage,
        limit: 20,
      );

      setState(() {
        _artworks.addAll(result.data);
        _isLoading = false;
        _hasMore = _currentPage < result.totalPages;
        _currentPage++;
      });
    } catch (e) {
      print('Error loading artworks: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadArtworks();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_artworks.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '${widget.userName} has no artworks yet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 700 ? 3 : 2;
        final childAspectRatio = width >= 700 ? 0.88 : 0.9;

        return GridView.builder(
          controller: _scrollController,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: _artworks.length + (_hasMore && _isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= _artworks.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final artwork = _artworks[index];
            return _buildArtworkCard(artwork);
          },
        );
      },
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtworkDetailScreen(artwork: artwork),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.network(
              artwork.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
            ),
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.75), Colors.transparent],
                ),
              ),
            ),
            // Title and stats
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (artwork.title != null && artwork.title!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        artwork.title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 14,
                        color: artwork.isLikedByMe
                            ? Colors.redAccent
                            : Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(artwork.likesCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.chat_bubble_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(artwork.commentsCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (artwork.isNSFW)
                        Text(
                          'NSFW',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
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
    );
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}
