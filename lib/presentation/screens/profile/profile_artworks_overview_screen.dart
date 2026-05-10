import 'package:flutter/material.dart';

import '../../../core/models/artwork_model.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/services/marketplace_service.dart';
import 'artwork_detail_screen.dart';

class ProfileArtworksOverviewScreen extends StatefulWidget {
  const ProfileArtworksOverviewScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<ProfileArtworksOverviewScreen> createState() =>
      _ProfileArtworksOverviewScreenState();
}

class _ProfileArtworksOverviewScreenState
    extends State<ProfileArtworksOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ArtworkService _artworkService;
  late final MarketplaceService _marketplaceService;

  bool _isLoadingOwned = true;
  bool _isLoadingBought = true;
  List<ArtworkModel> _ownedArtworks = <ArtworkModel>[];
  List<_BoughtArtworkRow> _boughtArtworks = <_BoughtArtworkRow>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _artworkService = ArtworkService();
    _marketplaceService = MarketplaceService();
    _loadOwnedArtworks();
    _loadBoughtArtworks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOwnedArtworks() async {
    setState(() => _isLoadingOwned = true);
    try {
      final result = await _artworkService.getMyArtworks(page: 1, limit: 100);
      if (!mounted) return;
      setState(() {
        _ownedArtworks = result.data;
        _isLoadingOwned = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingOwned = false);
    }
  }

  Future<void> _loadBoughtArtworks() async {
    setState(() => _isLoadingBought = true);
    try {
      final result = await _marketplaceService.getMyListings(
        page: 1,
        limit: 100,
        role: 'buyer',
      );
      final rows = (result['data'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();

      final bought = rows
          .where((row) {
            final status = (row['status'] ?? '').toString().toLowerCase();
            return status == 'sold' || status == 'sold_pending';
          })
          .map(_BoughtArtworkRow.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _boughtArtworks = bought;
        _isLoadingBought = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingBought = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName} Artworks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Owned (${_ownedArtworks.length})'),
            Tab(text: 'Bought (${_boughtArtworks.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOwnedTab(), _buildBoughtTab()],
      ),
    );
  }

  Widget _buildOwnedTab() {
    if (_isLoadingOwned) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ownedArtworks.isEmpty) {
      return _EmptyState(
        icon: Icons.brush_rounded,
        title: 'No owned artworks yet',
        subtitle: 'Once you create or buy artworks, they will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOwnedArtworks,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: _ownedArtworks.length,
        itemBuilder: (context, index) {
          final artwork = _ownedArtworks[index];
          return _OwnedArtworkCard(artwork: artwork);
        },
      ),
    );
  }

  Widget _buildBoughtTab() {
    if (_isLoadingBought) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_boughtArtworks.isEmpty) {
      return _EmptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'No bought artworks yet',
        subtitle: 'Purchased artworks from the marketplace will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBoughtArtworks,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: _boughtArtworks.length,
        itemBuilder: (context, index) {
          final row = _boughtArtworks[index];
          return _BoughtArtworkCard(row: row);
        },
      ),
    );
  }
}

class _OwnedArtworkCard extends StatelessWidget {
  const _OwnedArtworkCard({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArtworkDetailScreen(artwork: artwork),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              artwork.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.broken_image_rounded),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.72), Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                artwork.title?.trim().isNotEmpty == true
                    ? artwork.title!.trim()
                    : 'Untitled artwork',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoughtArtworkCard extends StatelessWidget {
  const _BoughtArtworkCard({required this.row});

  final _BoughtArtworkRow row;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            row.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image_rounded),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.78), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bought for ${row.price}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _BoughtArtworkRow {
  const _BoughtArtworkRow({
    required this.title,
    required this.imageUrl,
    required this.price,
  });

  final String title;
  final String imageUrl;
  final String price;

  factory _BoughtArtworkRow.fromJson(Map<String, dynamic> json) {
    final artwork = Map<String, dynamic>.from(
      json['artwork'] as Map? ?? const <String, dynamic>{},
    );
    final priceRaw = json['price'];
    final price = priceRaw is num
        ? priceRaw.toStringAsFixed(2)
        : (double.tryParse('$priceRaw') ?? 0).toStringAsFixed(2);
    final currency = (json['currency'] ?? 'USDC').toString();

    return _BoughtArtworkRow(
      title: (artwork['title'] ?? '').toString().trim().isEmpty
          ? 'Untitled artwork'
          : artwork['title'].toString(),
      imageUrl: (artwork['imageUrl'] ?? '').toString(),
      price: '$price $currency',
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
