// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/auth_service.dart';
import '../../../core/models/artwork_model.dart';
import '../../../core/services/artwork_service.dart';
import '../../../core/services/marketplace_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../report/report_screen.dart';
import '../splash/widgets/smoke_background.dart';
import 'art_detail_screen.dart';
import 'marketplace_balance_screen.dart';
import 'marketplace_negotiations_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  final ArtworkService _artworkService = ArtworkService();

  List<Map<String, dynamic>> _listings = const <Map<String, dynamic>>[];
  bool _isLoadingListings = false;
  String? _listingsError;
  bool _showMyListings = false;

  Map<String, dynamic>? _walletData;
  bool _isLoadingWallet = false;
  bool _isLoadingNegotiations = false;
  int _pendingNegotiationCount = 0;
  Map<String, Map<String, dynamic>> _myOpenNegotiationsByListing =
      <String, Map<String, dynamic>>{};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait([
      _loadListings(),
      _loadWallet(),
      _loadPendingNegotiationCount(),
      _loadMyOpenNegotiationsByListing(),
    ]);
  }

  Future<void> _loadMyOpenNegotiationsByListing() async {
    try {
      final result = await _marketplaceService.getMyNegotiations(
        status: 'all',
        limit: 200,
      );
      final rows = (result['data'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();

      final nextMap = <String, Map<String, dynamic>>{};
      for (final row in rows) {
        final isRequester = row['isRequester'] == true;
        if (!isRequester) continue;

        final status = (row['status'] ?? '').toString().toLowerCase();
        if (status != 'pending' && status != 'accepted') continue;

        final listingId = (row['listingId'] ?? '').toString();
        if (listingId.isEmpty) continue;

        final previous = nextMap[listingId];
        if (previous == null) {
          nextMap[listingId] = row;
          continue;
        }

        final prevUpdated = DateTime.tryParse(
          (previous['updatedAt'] ?? '').toString(),
        );
        final currUpdated = DateTime.tryParse(
          (row['updatedAt'] ?? '').toString(),
        );
        if (prevUpdated == null ||
            (currUpdated != null && currUpdated.isAfter(prevUpdated))) {
          nextMap[listingId] = row;
        }
      }

      if (!mounted) return;
      setState(() {
        _myOpenNegotiationsByListing = nextMap;
      });
    } catch (_) {
      // Keep silent if this hint data fails to load.
    }
  }

  Future<void> _loadPendingNegotiationCount() async {
    try {
      await MarketplaceService.ensureSeenLoaded();

      final result = await _marketplaceService.getMyNegotiations(
        status: 'all',
        limit: 100,
      );
      final rows = (result['data'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      await MarketplaceService.markNegotiationsBaseline(rows);

      final attentionIds = <String>{};
      for (final item in rows) {
        final negotiationId = (item['id'] ?? '').toString();
        if (negotiationId.isEmpty) continue;

        final status = (item['status'] ?? '').toString().toLowerCase();
        final isRequester = item['isRequester'] == true;

        if (status == 'pending' && !isRequester) {
          attentionIds.add(negotiationId);
          continue;
        }

        if (MarketplaceService.isNegotiationUnread(item)) {
          attentionIds.add(negotiationId);
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingNegotiationCount = attentionIds.length;
      });
    } catch (_) {
      // Keep silent for badge load failures.
    }
  }

  Future<void> _loadWallet() async {
    setState(() => _isLoadingWallet = true);
    try {
      final wallet = await _marketplaceService.getMyWallet();
      if (!mounted) return;
      setState(() {
        _walletData = wallet;
        _isLoadingWallet = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingWallet = false);
    }
  }

  Future<void> _loadListings() async {
    setState(() {
      _isLoadingListings = true;
      _listingsError = null;
    });

    try {
      final result = _showMyListings
          ? await _marketplaceService.getMyListings(limit: 30)
          : await _marketplaceService.getListings(limit: 30);
      final data = (result['data'] as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _listings = data;
        _isLoadingListings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _listingsError = e.toString();
        _isLoadingListings = false;
      });
    }
  }

  String _money(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return n.toStringAsFixed(2);
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  Future<void> _openBalance() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarketplaceBalanceScreen(service: _marketplaceService),
      ),
    );
    await _loadWallet();
  }

  Future<void> _buyListing(
    String listingId, {
    String? negotiationId,
    double? negotiatedAmount,
  }) async {
    final pageContext = context;
    final txHashController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            negotiationId == null
                ? 'Confirm purchase'
                : 'Buy at negotiated price',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (negotiatedAmount != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Negotiated price: ${_money(negotiatedAmount)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ethGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (negotiatedAmount != null) const SizedBox(height: 12),
              TextField(
                controller: txHashController,
                decoration: const InputDecoration(
                  labelText: 'Transaction hash (optional)',
                  hintText: '0x...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final txHash = txHashController.text.trim().isEmpty
                    ? null
                    : txHashController.text.trim();
                Navigator.of(context).pop();
                try {
                  await _marketplaceService.buyListing(
                    listingId,
                    negotiationId: negotiationId,
                    txHash: txHash,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(
                      content: Text('Purchase completed successfully'),
                    ),
                  );
                  await _loadInitial();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Purchase failed: $e')),
                  );
                }
              },
              child: const Text('Buy now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelListing(String listingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel listing'),
        content: const Text('Are you sure you want to cancel this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _marketplaceService.cancelListing(listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing cancelled')));
      await _loadListings();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to cancel listing: $e')));
    }
  }

  Future<void> _editListing(Map<String, dynamic> listing) async {
    final listingId = (listing['id'] ?? '').toString();
    if (listingId.isEmpty) return;

    final pageContext = context;
    final currentPrice = double.tryParse('${listing['price']}') ?? 0;
    final priceController = TextEditingController(
      text: currentPrice > 0 ? currentPrice.toStringAsFixed(2) : '',
    );
    bool negotiable = _asBool(listing['negotiable']);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit listing'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      hintText: 'e.g. 25',
                    ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: negotiable,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Negotiable price'),
                    subtitle: Text(
                      negotiable
                          ? 'Buyers can negotiate in chat'
                          : 'Fixed price only',
                    ),
                    onChanged: (value) {
                      setDialogState(() => negotiable = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final nextPrice = double.tryParse(
                      priceController.text.trim(),
                    );
                    if (nextPrice == null || nextPrice <= 0) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        const SnackBar(content: Text('Enter a valid price')),
                      );
                      return;
                    }

                    Navigator.of(context).pop();

                    try {
                      await _marketplaceService.updateListing(
                        listingId: listingId,
                        price: nextPrice,
                        negotiable: negotiable,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        const SnackBar(content: Text('Listing updated')),
                      );
                      await _loadInitial();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(content: Text('Unable to update listing: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _requestNegotiation(Map<String, dynamic> listing) async {
    final pageContext = context;
    final amountController = TextEditingController();
    final messageController = TextEditingController();

    final listedPrice = double.tryParse('${listing['price']}') ?? 0;
    if (listedPrice > 0) {
      amountController.text = listedPrice.toStringAsFixed(2);
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send negotiation request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Your offer amount',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  hintText: 'Hi, can you accept this offer?',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                  return;
                }

                Navigator.of(context).pop();
                try {
                  await _marketplaceService.requestNegotiation(
                    listingId: (listing['id'] ?? '').toString(),
                    amount: amount,
                    message: messageController.text.trim().isEmpty
                        ? null
                        : messageController.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(content: Text('Negotiation request sent')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(content: Text('Failed to send request: $e')),
                  );
                }
              },
              child: const Text('Send request'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openOrCreateNegotiation(Map<String, dynamic> listing) async {
    final listingId = (listing['id'] ?? '').toString();
    if (listingId.isEmpty) return;

    final existing = _myOpenNegotiationsByListing[listingId];
    if (existing == null) {
      await _requestNegotiation(listing);
      await _loadMyOpenNegotiationsByListing();
      return;
    }

    final status = (existing['status'] ?? '').toString().toLowerCase();
    if (status == 'accepted') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MarketplaceNegotiationChatScreen(
            service: _marketplaceService,
            negotiation: existing,
          ),
        ),
      );
      await _loadInitial();
      return;
    }

    await _openNegotiationsInbox();
  }

  Future<void> _openNegotiationsInbox() async {
    setState(() => _isLoadingNegotiations = true);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            MarketplaceNegotiationsScreen(service: _marketplaceService),
      ),
    );
    if (!mounted) return;
    setState(() => _isLoadingNegotiations = false);
    await _loadInitial();
  }

  Future<void> _showListArtworkSheet() async {
    final pageContext = context;
    List<ArtworkModel> myArtworks = const <ArtworkModel>[];
    ArtworkModel? selected;
    final priceController = TextEditingController();
    final txHashController = TextEditingController();
    bool negotiable = false;
    String currency = 'USDC';

    try {
      final result = await _artworkService.getMyArtworks(page: 1, limit: 50);
      myArtworks = result.data.where((artwork) => artwork.isPublic).toList();
      if (myArtworks.isNotEmpty) {
        selected = myArtworks.first;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to load artworks: $e')));
      return;
    }

    if (myArtworks.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need at least one public artwork to list.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: this.context.cardBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'List artwork on marketplace',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ArtworkModel>(
                      initialValue: selected,
                      items: myArtworks
                          .map(
                            (artwork) => DropdownMenuItem<ArtworkModel>(
                              value: artwork,
                              child: Text(
                                artwork.title?.isNotEmpty == true
                                    ? artwork.title!
                                    : 'Untitled artwork',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() => selected = value);
                      },
                      decoration: const InputDecoration(labelText: 'Artwork'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        hintText: 'e.g. 25',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: currency,
                      items: const [
                        DropdownMenuItem(value: 'USDC', child: Text('USDC')),
                        DropdownMenuItem(value: 'POL', child: Text('POL')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => currency = value);
                      },
                      decoration: const InputDecoration(labelText: 'Currency'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: negotiable,
                      onChanged: (value) {
                        setModalState(() => negotiable = value);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Negotiable price'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: txHashController,
                      decoration: const InputDecoration(
                        labelText: 'Listing tx hash (optional)',
                        hintText: '0x...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final selectedArtwork = selected;
                          final price = double.tryParse(
                            priceController.text.trim(),
                          );
                          if (selectedArtwork == null ||
                              price == null ||
                              price <= 0) {
                            return;
                          }

                          Navigator.of(context).pop();

                          try {
                            await _marketplaceService.createListing(
                              artworkId: selectedArtwork.id,
                              price: price,
                              currency: currency,
                              negotiable: negotiable,
                              txHash: txHashController.text.trim().isEmpty
                                  ? null
                                  : txHashController.text.trim(),
                            );

                            if (!mounted) return;
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              const SnackBar(
                                content: Text('Artwork listed successfully'),
                              ),
                            );
                            await _loadListings();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(pageContext).showSnackBar(
                              SnackBar(
                                content: Text('Failed to create listing: $e'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.sell_rounded),
                        label: const Text('List now'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    final wallet = _walletData?['wallet'] as Map<String, dynamic>?;

    return SmokeBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitial,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.ethGold.withValues(alpha: 0.3),
                                  AppColors.chainCyan.withValues(alpha: 0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.ethGold.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: AppColors.ethGold,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Marketplace',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Buy & sell AI art · Live market actions',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.chainCyan.withValues(
                                          alpha: 0.95,
                                        ),
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (_isLoadingWallet)
                                  Text(
                                    'Loading wallet…',
                                    style: TextStyle(color: textSecondary),
                                  )
                                else
                                  Text(
                                    'Balance: ${_money(wallet?['availableBalance'])} ${wallet?['currency'] ?? 'USDC'}',
                                    style: TextStyle(
                                      color: AppColors.ethGold,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _openBalance,
                            tooltip: 'Balance',
                            icon: const Icon(
                              Icons.account_balance_wallet_rounded,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              IconButton.filledTonal(
                                onPressed: _isLoadingNegotiations
                                    ? null
                                    : _openNegotiationsInbox,
                                tooltip: 'Negotiations',
                                icon: _isLoadingNegotiations
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.forum_rounded),
                              ),
                              if (_pendingNegotiationCount > 0)
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _pendingNegotiationCount > 9
                                          ? '9+'
                                          : '$_pendingNegotiationCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          IconButton.filled(
                            onPressed: _showListArtworkSheet,
                            tooltip: 'List artwork',
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Pill(
                            icon: Icons.sell_rounded,
                            label: '${_listings.length} active listings',
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          const _Pill(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Wallet enabled',
                            color: AppColors.ethGold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('All Listings'),
                            icon: Icon(Icons.public_rounded),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('My Listings'),
                            icon: Icon(Icons.person_rounded),
                          ),
                        ],
                        selected: {_showMyListings},
                        onSelectionChanged: (selection) async {
                          final selected = selection.first;
                          if (_showMyListings == selected) return;
                          setState(() => _showMyListings = selected);
                          await _loadListings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoadingListings)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_listingsError != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      _listingsError!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                )
              else if (_listings.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No active listings yet. Create your first listing.',
                      style: TextStyle(color: textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _listings[index];
                      final artwork =
                          item['artwork'] as Map<String, dynamic>? ??
                          <String, dynamic>{};
                      final seller =
                          item['seller'] as Map<String, dynamic>? ??
                          <String, dynamic>{};

                      final listingId = (item['id'] ?? '').toString();
                      final isMine = _asBool(item['isMine']);
                      final negotiable = _asBool(item['negotiable']);
                      final isActive = _asBool(item['isActive']);
                      final status = (item['status'] ?? '').toString();
                      final canCancel =
                          isMine &&
                          isActive &&
                          (status == 'listed' || status == 'listed_onchain');
                      final canEdit = canCancel;
                      final existingNegotiation =
                          _myOpenNegotiationsByListing[listingId];

                      final sellerName = (seller['name'] ?? '')
                          .toString()
                          .trim();
                      final artistLabel = sellerName.isNotEmpty
                          ? sellerName
                          : (isMine ? 'You' : 'Unknown artist');

                      return _ListingCard(
                        title: (artwork['title'] ?? 'Untitled artwork')
                            .toString(),
                        artist: artistLabel,
                        price: _money(item['price']),
                        currency: (item['currency'] ?? 'USDC').toString(),
                        imageUrl: artwork['imageUrl']?.toString(),
                        imageColor: AppColors.polygonPurple,
                        negotiable: negotiable,
                        isMine: isMine,
                        status: status,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onReport: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportScreen(
                                authService: widget.authService,
                                initialType: 'artwork',
                                targetId: listingId,
                                targetLabel: (artwork['title'] ?? 'Artwork')
                                    .toString(),
                              ),
                            ),
                          );
                        },
                        onTap: () {
                          Navigator.of(context).push(
                            ArtDetailScreen.route(
                              ArtDetailScreen(
                                title: (artwork['title'] ?? 'Untitled artwork')
                                    .toString(),
                                artist: artistLabel,
                                price: _money(item['price']),
                                currency: (item['currency'] ?? 'USDC')
                                    .toString(),
                                priceUsd: null,
                                imageUrl: artwork['imageUrl']?.toString(),
                                imageColor: AppColors.polygonPurple,
                                negotiable: negotiable,
                              ),
                            ),
                          );
                        },
                        onBuy: isMine ? null : () => _buyListing(listingId),
                        onNegotiate: (!isMine && negotiable)
                            ? () => _openOrCreateNegotiation(item)
                            : null,
                        negotiateLabel: (!isMine && negotiable)
                            ? (existingNegotiation != null
                                  ? 'Continue'
                                  : 'Negotiate')
                            : null,
                        onCancel: canCancel
                            ? () => _cancelListing(listingId)
                            : null,
                        onEdit: canEdit ? () => _editListing(item) : null,
                      );
                    }, childCount: _listings.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.title,
    required this.artist,
    required this.price,
    required this.currency,
    this.imageUrl,
    required this.imageColor,
    required this.negotiable,
    required this.isMine,
    required this.status,
    required this.textPrimary,
    required this.textSecondary,
    this.onTap,
    this.onReport,
    this.onBuy,
    this.onNegotiate,
    this.negotiateLabel,
    this.onCancel,
    this.onEdit,
  });

  final String title;
  final String artist;
  final String price;
  final String currency;
  final String? imageUrl;
  final Color imageColor;
  final bool negotiable;
  final bool isMine;
  final String status;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback? onTap;
  final VoidCallback? onReport;
  final VoidCallback? onBuy;
  final VoidCallback? onNegotiate;
  final String? negotiateLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cardBg = context.cardBackgroundColor;
    final border = context.borderColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.chainCyan.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.polygonPurple.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 160,
                        width: double.infinity,
                        color: imageColor,
                        child: imageUrl != null && imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 160,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 48,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 48,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isMine
                                        ? AppColors.polygonPurple
                                        : AppColors.success)
                                    .withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMine
                                ? 'Your Listing · ${status.toUpperCase()}'
                                : status.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          artist,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.monetization_on_rounded,
                              color: AppColors.ethGold,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$price $currency',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.ethGold,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        if (isMine) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                negotiable
                                    ? Icons.handshake_rounded
                                    : Icons.lock_rounded,
                                color: AppColors.chainCyan,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                negotiable
                                    ? 'Terms: Negotiable'
                                    : 'Terms: Fixed price',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.chainCyan,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onBuy,
                                icon: Icon(
                                  isMine
                                      ? Icons.verified_rounded
                                      : Icons.shopping_bag_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  isMine ? 'Owned' : 'Buy',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.chainCyan,
                                  side: BorderSide(
                                    color: AppColors.chainCyan.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: isMine
                                    ? onEdit
                                    : (negotiable ? onNegotiate : null),
                                icon: Icon(
                                  isMine
                                      ? Icons.tune_rounded
                                      : Icons.handshake_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  isMine
                                      ? 'Edit terms'
                                      : (negotiable
                                            ? (negotiateLabel ?? 'Negotiate')
                                            : 'Fixed'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: isMine
                                      ? AppColors.chainCyan.withValues(
                                          alpha: 0.85,
                                        )
                                      : AppColors.ethGold,
                                  foregroundColor: isMine
                                      ? Colors.white
                                      : Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isMine)
                              GestureDetector(
                                onTap: onReport,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.report_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (onCancel != null) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: onCancel,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
