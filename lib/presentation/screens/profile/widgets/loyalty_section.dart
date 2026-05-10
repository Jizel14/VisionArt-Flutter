import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../features/loyalty/models/loyalty_model.dart';
import '../../../../features/loyalty/services/loyalty_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_extensions.dart';

class LoyaltySection extends StatefulWidget {
  const LoyaltySection({super.key});

  @override
  State<LoyaltySection> createState() => _LoyaltySectionState();
}

class _LoyaltySectionState extends State<LoyaltySection> {
  final _svc = LoyaltyService();
  Future<LoyaltyMe>? _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = _svc.getMe();
  }

  Future<void> _refresh() async {
    setState(() => _future = _svc.getMe());
  }

  Future<void> _redeem(int points) async {
    setState(() => _busy = true);
    try {
      final months = await _svc.redeem(points);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redeemed: $months month(s) PRO'),
          backgroundColor: Colors.green,
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: context.cardBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.isDark
                  ? AppColors.primaryBlue.withValues(alpha: 0.25)
                  : context.borderColor.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<LoyaltyMe>(
              future: _future,
              builder: (context, snap) {
                final loading = snap.connectionState == ConnectionState.waiting;
                final data = snap.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: Color(0xFF7C3AED)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Loyalty Points',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _busy ? null : _refresh,
                          icon: Icon(Icons.refresh_rounded,
                              color: textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loading
                          ? 'Loading…'
                          : data == null
                              ? 'Not available'
                              : '${data.balance} points',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Convert points to free PRO months.',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (data != null && data.tiers.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: data.tiers.map((t) {
                          final can = data.balance >= t.points;
                          return OutlinedButton(
                            onPressed: (_busy || !can)
                                ? null
                                : () => _redeem(t.points),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: can
                                  ? const Color(0xFF7C3AED)
                                  : textSecondary,
                              side: BorderSide(
                                color: can
                                    ? const Color(0xFF7C3AED)
                                    : textSecondary.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('${t.points} → ${t.label}'),
                          );
                        }).toList(),
                      ),
                    if (snap.hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        snap.error.toString(),
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

