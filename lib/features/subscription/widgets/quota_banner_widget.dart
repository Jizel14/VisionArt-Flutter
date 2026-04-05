import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../screens/subscription_screen.dart';

/// Reusable banner showing remaining generations.
/// Shows nothing if the user is Pro.
/// Shows a red urgent banner if quota is at 0.
class QuotaBanner extends StatelessWidget {
  const QuotaBanner({
    super.key,
    required this.subscription,
    this.compact = false,
  });

  final SubscriptionModel subscription;

  /// When true, renders a small inline chip instead of a full banner.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Pro users: show a small badge and nothing more
    if (subscription.isPro) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                size: 14, color: Color(0xFF7C3AED)),
            SizedBox(width: 4),
            Text(
              'Pro',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      );
    }

    final remaining = subscription.generationsRemaining;
    final isUrgent = remaining == 0;
    final color = isUrgent ? Colors.red : const Color(0xFF7C3AED);

    if (compact) {
      return GestureDetector(
        onTap: () => _navigateToPaywall(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isUrgent ? 'No generations left' : '$remaining left',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: isUrgent ? () => _navigateToPaywall(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              isUrgent
                  ? Icons.warning_amber_rounded
                  : Icons.auto_awesome_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUrgent
                    ? 'You\'ve used all your free generations this month.'
                    : '$remaining generation${remaining == 1 ? '' : 's'} remaining this month.',
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isUrgent) ...[
              const SizedBox(width: 8),
              Text(
                'Upgrade',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }
}
