import 'package:flutter/material.dart';

import '../../../core/services/marketplace_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_extensions.dart';
import '../splash/widgets/smoke_background.dart';

class MarketplaceAnalyticsScreen extends StatefulWidget {
  const MarketplaceAnalyticsScreen({super.key, required this.service});

  final MarketplaceService service;

  @override
  State<MarketplaceAnalyticsScreen> createState() =>
      _MarketplaceAnalyticsScreenState();
}

class _MarketplaceAnalyticsScreenState
    extends State<MarketplaceAnalyticsScreen> {
  Map<String, dynamic>? _payload;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final payload = await widget.service.getSellerAnalytics();
      if (!mounted) return;
      setState(() {
        _payload = payload;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _money(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return number.toStringAsFixed(2);
  }

  double _ratio(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return number.clamp(0, 1).toDouble();
  }

  int _intValue(Map<String, dynamic> summary, String key) {
    final value = summary[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Unknown';
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '$value';
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
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = Map<String, dynamic>.from(
      _payload?['summary'] as Map? ?? const {},
    );
    final recentSales =
        (_payload?['recentSales'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();

    return Scaffold(
      body: SmokeBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seller analytics',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Track sales, negotiations, and listing performance',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: context.textSecondaryColor,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _HeroMetricsCard(
                        soldListings: _intValue(summary, 'soldListings'),
                        totalRevenue: _money(summary['totalSoldRevenue']),
                        averagePrice: _money(summary['averageSoldPrice']),
                        acceptanceRate: _ratio(
                          summary['negotiationAcceptanceRate'],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Top insights',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _InsightChip(
                              label: 'Sold listings',
                              value: '${_intValue(summary, 'soldListings')}',
                              color: AppColors.success,
                            ),
                            _InsightChip(
                              label: 'Pending negotiations',
                              value:
                                  '${_intValue(summary, 'pendingNegotiations')}',
                              color: AppColors.accentPink,
                            ),
                            _InsightChip(
                              label: 'Negotiable share',
                              value:
                                  '${_intValue(summary, 'negotiableListings')} / ${_intValue(summary, 'totalListings')}',
                              color: AppColors.ethGold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.12,
                        children: [
                          _StatTile(
                            label: 'Active listings',
                            value: '${_intValue(summary, 'activeListings')}',
                            icon: Icons.sell_rounded,
                            color: AppColors.chainCyan,
                          ),
                          _StatTile(
                            label: 'Negotiable',
                            value:
                                '${_intValue(summary, 'negotiableListings')}',
                            icon: Icons.handshake_rounded,
                            color: AppColors.ethGold,
                          ),
                          _StatTile(
                            label: 'Fixed',
                            value: '${_intValue(summary, 'fixedListings')}',
                            icon: Icons.lock_rounded,
                            color: AppColors.primaryBlue,
                          ),
                          _StatTile(
                            label: 'Pending negotiations',
                            value:
                                '${_intValue(summary, 'pendingNegotiations')}',
                            icon: Icons.forum_rounded,
                            color: AppColors.accentPink,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Negotiation overview',
                        child: Column(
                          children: [
                            _LinearInfoRow(
                              label: 'Accepted',
                              value: _intValue(
                                summary,
                                'acceptedNegotiations',
                              ).toString(),
                              color: AppColors.success,
                            ),
                            const SizedBox(height: 12),
                            _LinearInfoRow(
                              label: 'Denied',
                              value: _intValue(
                                summary,
                                'deniedNegotiations',
                              ).toString(),
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 12),
                            _LinearInfoRow(
                              label: 'Closed',
                              value: _intValue(
                                summary,
                                'closedNegotiations',
                              ).toString(),
                              color: AppColors.polygonPurple,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Recent sales',
                        child: recentSales.isEmpty
                            ? Text(
                                'No completed sales yet.',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                ),
                              )
                            : Column(
                                children: recentSales
                                    .map(
                                      (sale) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _SaleTile(
                                          title:
                                              (sale['title'] ??
                                                      'Untitled artwork')
                                                  .toString(),
                                          buyerName:
                                              (sale['buyerName'] ??
                                                      'Unknown buyer')
                                                  .toString(),
                                          price: _money(sale['price']),
                                          currency: (sale['currency'] ?? 'USDC')
                                              .toString(),
                                          soldAt: _formatDate(sale['soldAt']),
                                          imageUrl: sale['imageUrl']
                                              ?.toString(),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroMetricsCard extends StatelessWidget {
  const _HeroMetricsCard({
    required this.soldListings,
    required this.totalRevenue,
    required this.averagePrice,
    required this.acceptanceRate,
  });

  final int soldListings;
  final String totalRevenue;
  final String averagePrice;
  final double acceptanceRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.polygonPurple.withValues(alpha: 0.8),
            AppColors.chainCyan.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue snapshot',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(label: 'Sold', value: '$soldListings'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: 'Revenue',
                  value: '$totalRevenue USDC',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: 'Avg price',
                  value: '$averagePrice USDC',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniMetric(
                  label: 'Accept rate',
                  value: '${(acceptanceRate * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LinearInfoRow extends StatelessWidget {
  const _LinearInfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(color: context.textPrimaryColor)),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({
    required this.title,
    required this.buyerName,
    required this.price,
    required this.currency,
    required this.soldAt,
    this.imageUrl,
  });

  final String title;
  final String buyerName;
  final String price;
  final String currency;
  final String soldAt;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 56,
            height: 56,
            color: AppColors.polygonPurple.withValues(alpha: 0.2),
            child: imageUrl == null || imageUrl!.isEmpty
                ? const Icon(Icons.image_rounded)
                : Image.network(imageUrl!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                buyerName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                soldAt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$price $currency',
          style: TextStyle(
            color: AppColors.ethGold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
