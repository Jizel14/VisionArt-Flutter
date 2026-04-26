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
import '../../widgets/ai_audio_widgets.dart';

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
      backgroundColor: AppThemeColors.surfaceColor(context),
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
        color: AppThemeColors.cardBackgroundColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(
          color: AppThemeColors.borderColor(context).withOpacity(0.5),
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

          // Visual Indicator for Audio
          if (artwork.audioUrl != null)
            Positioned(
              top: 12,
              left: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
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
  bool _isGeneratingVideo = false;
  bool _isGeneratingAudio = false;
  String? _audioUrl;
  final _visionCraft = VisionCraftService();
  final _artworkService = ArtworkService();

  // ── Similar artworks state ───────────────────────────────────────────────
  List<ArtworkModel> _similarArtworks = [];
  bool _loadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _audioUrl = widget.artwork.audioUrl;
    _loadSimilarArtworks();
  }

  Future<void> _loadSimilarArtworks() async {
    setState(() => _loadingSimilar = true);
    try {
      final similar = await _artworkService.getSimilarArtworks(
        widget.artwork.id,
        limit: 6,
        generate: true,
      );
      if (mounted) {
        setState(() {
          _similarArtworks = similar;
          _loadingSimilar = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  void _openSimilarArtwork(BuildContext context, ArtworkModel artwork) {
    Navigator.of(context).pop(); // close current sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ArtworkDetailsBottomSheet(artwork: artwork),
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

  Future<void> _generateVideo() async {
    setState(() => _isGeneratingVideo = true);
    try {
      final videoUrl = await _visionCraft.generateVideo(widget.artwork.id);
      if (videoUrl != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: const Text('🎬 Video generated successfully!'),
            backgroundColor: AppColors.primaryBlue,
            action: SnackBarAction(label: 'Watch', onPressed: () => launchUrl(Uri.parse(videoUrl))),
          ),
        );
        launchUrl(Uri.parse(videoUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Video failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingVideo = false);
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
      height: screenHeight * 0.9,
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
              // Top Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppThemeColors.textSecondaryColor(context).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The Main Image
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
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              InteractiveViewer(
                                child: imageProvider != null
                                    ? Image(
                                        image: imageProvider,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 300, color: AppColors.border),
                              ),
                              if (_audioUrl != null)
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: FadeInUp(
                                    duration: const Duration(milliseconds: 500),
                                    child: SimpleAudioPlayer(url: _audioUrl!),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

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
                      const SizedBox(height: 28),

                      // ═══ "More Like This" — Pinterest-style section ═══════
                      _buildSimilarSection(context, isDark),

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

                // 2. Audio Generation
                AudioGenButton(
                  artworkId: widget.artwork.id,
                  onStarted: () => setState(() => _isGeneratingAudio = true),
                  onComplete: (url) => setState(() {
                    _isGeneratingAudio = false;
                    _audioUrl = url;
                  }),
                  onError: () => setState(() => _isGeneratingAudio = false),
                  color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                ),

                const SizedBox(width: 12),
                
                // 3. Save Button
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

          if (_isGeneratingAudio)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      'Composition de votre univers sonore...',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          if (_audioUrl != null)
             Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: SimpleAudioPlayer(url: _audioUrl!),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Pinterest-style "More Like This" section
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSimilarSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.2),
                    AppColors.primaryBlue.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome_mosaic_rounded,
                  size: 18, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            const Text(
              'More Like This',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            if (_loadingSimilar)
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
        const SizedBox(height: 6),
        Text(
          'Discover similar artworks based on style & content',
          style: TextStyle(
            fontSize: 12,
            color: AppThemeColors.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: 16),

        if (_loadingSimilar)
          _buildShimmerPlaceholders(isDark)
        else if (_similarArtworks.isEmpty)
          _buildEmptySimilar(context, isDark)
        else
          _buildSimilarGrid(context, isDark),
      ],
    );
  }

  Widget _buildShimmerPlaceholders(bool isDark) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) {
          return Padding(
            padding: EdgeInsets.only(right: index < 2 ? 12 : 0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: Duration(milliseconds: 800 + index * 200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Colors.white10, Colors.white.withOpacity(0.04)]
                            : [Colors.black.withOpacity(0.06), Colors.black.withOpacity(0.02)],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySimilar(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppThemeColors.borderColor(context).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 32, color: AppColors.primaryPurple.withOpacity(0.4)),
          const SizedBox(height: 12),
          Text(
            'Keep creating to find similarities',
            style: TextStyle(color: AppThemeColors.textSecondaryColor(context), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarGrid(BuildContext context, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _similarArtworks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final art = _similarArtworks[index];
        final provider = _imageProviderFor(art);
        return GestureDetector(
          onTap: () => _openSimilarArtwork(context, art),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppThemeColors.borderColor(context).withOpacity(0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: provider != null
                ? Image(image: provider, fit: BoxFit.cover)
                : Container(color: Colors.grey.withOpacity(0.1)),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: AppThemeColors.textSecondaryColor(context).withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppThemeColors.textPrimaryColor(context),
          ),
        ),
      ],
    );
  }
}
