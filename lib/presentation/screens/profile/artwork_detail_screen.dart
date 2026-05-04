import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/artwork_model.dart';
import '../../../core/services/marketplace_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/social_share_sheet.dart';
import 'profile_inspect_screen.dart';

class ArtworkDetailScreen extends StatefulWidget {
  final ArtworkModel artwork;

  const ArtworkDetailScreen({super.key, required this.artwork});

  @override
  State<ArtworkDetailScreen> createState() => _ArtworkDetailScreenState();
}

class _ArtworkDetailScreenState extends State<ArtworkDetailScreen> {
  late ArtworkModel _artwork;
  final MarketplaceService _marketplaceService = MarketplaceService();
  late bool _isLiked;
  late int _likesCount;
  bool _isMinting = false;

  ArtworkModel get artwork => _artwork;

  @override
  void initState() {
    super.initState();
    _artwork = widget.artwork;
    _isLiked = artwork.isLikedByMe;
    _likesCount = artwork.likesCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
  }

  void _onShare() {
    final link = 'https://visionart.app/artworks/${artwork.id}';
    final title = artwork.title?.isNotEmpty == true
        ? artwork.title!
        : 'Untitled artwork';
    final caption = '$title by @${artwork.user.name}\n$link';

    showSocialShareSheet(
      context: context,
      link: link,
      caption: caption,
      subject: '$title – VisionArt',
    );
  }

  Map<String, dynamic>? get _nftData {
    final metadata = artwork.metadata;
    if (metadata == null) return null;

    final nft = metadata['nft'];
    if (nft is Map<String, dynamic>) {
      return nft;
    }

    return null;
  }

  Future<void> _mintArtwork() async {
    if (_isMinting) return;

    final addressController = TextEditingController();
    final recipientAddress = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mint as NFT'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your MetaMask wallet address to receive the NFT:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                hintText: '0x...',
                labelText: 'Recipient wallet address',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, addressController.text.trim()),
            child: const Text('Mint'),
          ),
        ],
      ),
    );

    if (recipientAddress == null || recipientAddress.isEmpty) return;

    if (!RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(recipientAddress)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid wallet address')));
      return;
    }

    setState(() => _isMinting = true);
    try {
      final response = await _marketplaceService.mintArtworkNft(
        artworkId: artwork.id,
        recipientAddress: recipientAddress,
      );

      final updatedArtworkJson = response['artwork'];
      if (updatedArtworkJson is Map<String, dynamic>) {
        _artwork = ArtworkModel.fromJson(updatedArtworkJson);
      }

      if (!mounted) return;
      setState(() {});

      final nft = response['nft'];
      final tokenId = nft is Map ? '${nft['tokenId'] ?? ''}' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tokenId.isNotEmpty
                ? 'NFT minted successfully. Token #$tokenId is now on chain.'
                : 'NFT minted successfully on chain.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mint failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isMinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;
    final nftData = _nftData;
    final canMint = artwork.isPublic && nftData == null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.width,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _onShare,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'artwork_image_${artwork.id}',
                child: CachedNetworkImage(
                  imageUrl: artwork.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) {
                    return Container(
                      color: context.surfaceColor,
                      child: const Icon(
                        Icons.broken_image_rounded,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title?.isNotEmpty == true
                        ? artwork.title!
                        : 'Untitled',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileInspectScreen(
                            userId: artwork.user.id,
                            initialUser: artwork.user,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryBlue.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundImage: artwork.user.avatarUrl != null
                                ? NetworkImage(artwork.user.avatarUrl!)
                                : null,
                            child: artwork.user.avatarUrl == null
                                ? const Icon(Icons.person_rounded)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      artwork.user.name,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: textPrimary,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (artwork.user.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '@${artwork.user.email.split('@')[0]}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (artwork.description != null &&
                      artwork.description!.isNotEmpty) ...[
                    Text(
                      artwork.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Likes', _likesCount, context),
                      _buildStatItem(
                        'Comments',
                        artwork.commentsCount,
                        context,
                      ),
                      _buildStatItem('Remixes', artwork.remixCount, context),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          label: 'Like',
                          isSelected: _isLiked,
                          onTap: _toggleLike,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Comment',
                          isSelected: false,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.repeat_rounded,
                          label: 'Remix',
                          isSelected: false,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildGlassCard(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.token_rounded,
                                color: AppColors.nftAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                nftData == null
                                    ? 'Mint as NFT'
                                    : 'On-chain NFT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (nftData == null) ...[
                            Text(
                              artwork.isPublic
                                  ? 'Mint this public artwork to Polygon Amoy and persist the token metadata on-chain.'
                                  : 'Make this artwork public before minting it as an NFT.',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: canMint && !_isMinting
                                    ? _mintArtwork
                                    : null,
                                icon: _isMinting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black87,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  _isMinting ? 'Minting...' : 'Mint NFT',
                                ),
                              ),
                            ),
                          ] else ...[
                            _buildMetadataRow(
                              'Contract',
                              _shortenAddress(
                                '${nftData['contractAddress'] ?? '-'}',
                              ),
                              context,
                            ),
                            _buildMetadataRow(
                              'Token ID',
                              '${nftData['tokenId'] ?? '-'}',
                              context,
                            ),
                            _buildMetadataRow(
                              'Tx hash',
                              _shortenAddress(
                                '${nftData['transactionHash'] ?? '-'}',
                              ),
                              context,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Minted at ${_formatDateTime('${nftData['mintedAt'] ?? ''}')}',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final txHash =
                                        '${nftData['transactionHash'] ?? ''}';
                                    if (txHash.isEmpty) return;
                                    await Clipboard.setData(
                                      ClipboardData(text: txHash),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Transaction hash copied',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy_rounded),
                                  label: const Text('Copy tx hash'),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final txHash =
                                        '${nftData['transactionHash'] ?? ''}';
                                    if (txHash.isEmpty) return;
                                    final uri = Uri.parse(
                                      'https://amoy.polygonscan.com/tx/$txHash',
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('View on explorer'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (artwork.remixedFrom != null) ...[
                    _buildGlassCard(
                      context: context,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.repeat_rounded,
                              color: AppColors.accentPink,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Remixed from',
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    artwork.remixedFrom!.user.name,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildGlassCard(
                    context: context,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildMetadataRow(
                            'Created',
                            _formatDate(artwork.createdAt),
                            context,
                          ),
                          _buildMetadataRow(
                            'Visibility',
                            artwork.isPublic ? 'Public' : 'Private',
                            context,
                          ),
                          if (artwork.isNSFW)
                            _buildMetadataRow(
                              'Content',
                              'Contains NSFW content',
                              context,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required BuildContext context,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDark
                  ? AppColors.primaryBlue.withOpacity(0.2)
                  : context.borderColor.withOpacity(0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
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
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return 'Unknown';
    return _formatDate(parsed);
  }

  String _shortenAddress(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 6)}...${value.substring(value.length - 4)}';
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    if (isSelected) {
      bgColor = AppColors.accentPink.withOpacity(0.15);
      fgColor = AppColors.accentPink;
      borderColor = AppColors.accentPink.withOpacity(0.5);
    } else {
      bgColor = isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.04);
      fgColor = context.textPrimaryColor;
      borderColor = context.borderColor.withOpacity(0.5);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fgColor, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: fgColor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
