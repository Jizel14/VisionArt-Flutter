import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

import '../../../core/api_client.dart';
import '../../../core/models/artwork_model.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/web_download.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.userId});

  final String userId;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _artworkService = ArtworkService();
  final List<ArtworkModel> _artworks = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadGallery();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadGallery() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _artworkService.getUserGallery(
        userId: widget.userId,
        page: 1,
      );
      if (mounted) {
        setState(() {
          _artworks.clear();
          _artworks.addAll(res.data);
          _page = res.page;
          _totalPages = res.totalPages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _totalPages) return;

    setState(() => _loadingMore = true);

    try {
      final res = await _artworkService.getUserGallery(
        userId: widget.userId,
        page: _page + 1,
      );
      if (mounted) {
        setState(() {
          _artworks.addAll(res.data);
          _page = res.page;
          _totalPages = res.totalPages;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _showArtworkDetails(BuildContext context, ArtworkModel artwork) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArtworkDetailsBottomSheet(artwork: artwork),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        title: const Text(
          'My Masterpieces',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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

    return RefreshIndicator(
      onRefresh: _loadGallery,
      color: AppColors.primaryPurple,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75, // Taller cards for "portrait" feel
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
              onTap: () => _showArtworkDetails(context, artwork),
              child: _GalleryItem(artwork: artwork),
            ),
          );
        },
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
                ]
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
  const _ArtworkDetailsBottomSheet({required this.artwork});

  final ArtworkModel artwork;

  @override
  State<_ArtworkDetailsBottomSheet> createState() =>
      _ArtworkDetailsBottomSheetState();
}

class _ArtworkDetailsBottomSheetState
    extends State<_ArtworkDetailsBottomSheet> {
  bool _isSaving = false;

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
              // Top Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Image Viewer
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The Image
                      Hero(
                        tag: 'artwork_image_${widget.artwork.id}',
                        child: Container(
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
                          child: InteractiveViewer(
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
                      const SizedBox(height: 32),

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
                                color: context.textPrimaryColor.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Divider(color: context.borderColor.withOpacity(0.5)),
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
                          const Icon(Icons.download_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'Save to Device',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
    );
  }

  String _formatDate(DateTime date) {
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
