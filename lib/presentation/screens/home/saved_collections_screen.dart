import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/models/artwork_model.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

class SavedCollectionsScreen extends StatefulWidget {
  const SavedCollectionsScreen({super.key});

  @override
  State<SavedCollectionsScreen> createState() => _SavedCollectionsScreenState();
}

class _SavedCollectionsScreenState extends State<SavedCollectionsScreen> {
  final ArtworkService _artworkService = ArtworkService();

  List<CollectionSummary> _collections = [];
  List<ArtworkModel> _savedArtworks = [];
  String? _selectedCollection;
  bool _isLoadingCollections = true;
  bool _isLoadingArtworks = true;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    try {
      final collections = await _artworkService.getCollections();
      if (!mounted) return;

      setState(() {
        _collections = collections;
        _selectedCollection = collections.isNotEmpty
            ? collections.first.name
            : null;
        _isLoadingCollections = false;
      });

      await _loadSavedArtworks();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _collections = [];
        _selectedCollection = null;
        _isLoadingCollections = false;
        _isLoadingArtworks = false;
      });
    }
  }

  Future<void> _loadSavedArtworks() async {
    setState(() => _isLoadingArtworks = true);

    try {
      final result = await _artworkService.getSavedArtworks(
        collectionName: _selectedCollection,
      );

      if (!mounted) return;
      setState(() {
        _savedArtworks = result.data;
        _isLoadingArtworks = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _savedArtworks = [];
        _isLoadingArtworks = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final totalSaved = _collections.fold<int>(
      0,
      (sum, item) => sum + item.itemsCount,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Saved Collections'),
      ),
      body: SmokeBackground(
        child: Padding(
          padding: EdgeInsets.only(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.borderColor.withOpacity(0.45),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.bookmark_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your saved art',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedCollection != null
                                  ? '$totalSaved total • Collection: $_selectedCollection'
                                  : '$totalSaved saved artworks',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _isLoadingCollections
                    ? const LinearProgressIndicator()
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _collections
                              .map(
                                (collection) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    selected:
                                        _selectedCollection == collection.name,
                                    label: Text(
                                      '${collection.name} (${collection.itemsCount})',
                                    ),
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedCollection = collection.name;
                                      });
                                      _loadSavedArtworks();
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoadingArtworks
                    ? const Center(child: CircularProgressIndicator())
                    : _savedArtworks.isEmpty
                    ? Center(
                        child: Text(
                          'No saved artworks yet',
                          style: TextStyle(color: textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _savedArtworks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final artwork = _savedArtworks[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: context.cardBackgroundColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(14),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: artwork.imageUrl,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artwork.title?.isNotEmpty == true
                                              ? artwork.title!
                                              : 'Untitled artwork',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'by ${artwork.user.name}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.favorite_rounded,
                                              size: 16,
                                              color: textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${artwork.likesCount}',
                                              style: TextStyle(
                                                color: textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.mode_comment_outlined,
                                              size: 16,
                                              color: textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${artwork.commentsCount}',
                                              style: TextStyle(
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
