import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../widgets/plan_card_widget.dart';
import 'checkout_webview_screen.dart';
import '../../../core/api_client.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _service = SubscriptionService();

  SubscriptionModel? _subscription;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sub = await _service.getMySubscription();
      if (mounted) setState(() => _subscription = sub);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startUpgrade() async {
    setState(() => _actionLoading = true);
    try {
      final result = await _service.createCheckoutSession();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutWebviewScreen(
            checkoutUrl: result.checkoutUrl,
            onSuccess: () => _loadSubscription(),
            onCancel: () {},
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _cancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel subscription?'),
        content: Text(
          _subscription?.currentPeriodEnd != null
              ? 'Your Pro access will continue until ${DateFormat.yMMMd().format(_subscription!.currentPeriodEnd!.toLocal())}.'
              : 'You will lose Pro access at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Pro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _actionLoading = true);
    try {
      final msg = await _service.cancelSubscription();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        _loadSubscription();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadSubscription)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final sub = _subscription ?? SubscriptionModel.defaultFree();

    return RefreshIndicator(
      onRefresh: _loadSubscription,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Current usage banner ────────────────────────────────────────
            if (sub.isFree) ...[
              _UsageBanner(subscription: sub),
              const SizedBox(height: 24),
            ],

            const Text(
              'Choose your plan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ── Free plan card ──────────────────────────────────────────────
            PlanCard(
              title: 'Free',
              price: '\$0',
              period: 'forever',
              features: const [
                '10 AI generations / month',
                'Standard resolution',
                'Basic styles only',
                'Up to 3 collections',
              ],
              isCurrent: sub.isFree,
              isHighlighted: false,
            ),
            const SizedBox(height: 16),

            // ── Pro plan card ───────────────────────────────────────────────
            PlanCard(
              title: 'Pro',
              price: '\$9.99',
              period: '/ month',
              features: const [
                'Unlimited AI generations',
                'HD resolution',
                'All styles & models',
                'Unlimited collections',
                'Full marketplace access',
              ],
              isCurrent: sub.isPro,
              isHighlighted: true,
            ),
            const SizedBox(height: 32),

            // ── CTA ─────────────────────────────────────────────────────────
            if (sub.isFree) ...[
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _actionLoading ? null : _startUpgrade,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _actionLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Upgrade to Pro — \$9.99/month',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],

            if (sub.isPro) ...[
              if (sub.currentPeriodEnd != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Renews on ${DateFormat.yMMMd().format(sub.currentPeriodEnd!.toLocal())}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              OutlinedButton(
                onPressed: _actionLoading ? null : _cancelSubscription,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cancel Subscription'),
              ),
            ],

            if (sub.isFree && sub.quotaResetAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Quota resets on ${DateFormat.yMMMd().format(sub.quotaResetAt!.toLocal())}',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UsageBanner extends StatelessWidget {
  const _UsageBanner({required this.subscription});
  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final used = subscription.generationsUsedThisMonth;
    final limit = subscription.quotaLimit ?? 10;
    final remaining = subscription.generationsRemaining;
    final pct = (used / limit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: remaining == 0
            ? Colors.red.withOpacity(0.08)
            : Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: remaining == 0
              ? Colors.red.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Generations this month',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: remaining == 0 ? Colors.red : null,
                ),
              ),
              Text(
                '$used / $limit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: remaining == 0 ? Colors.red : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                remaining == 0 ? Colors.red : const Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
