import 'package:flutter/material.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrent,
    required this.isHighlighted,
  });

  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrent;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? purple.withOpacity(0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? purple : Colors.grey.withOpacity(0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isHighlighted ? purple : Colors.transparent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.white : null,
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHighlighted
                          ? Colors.white.withOpacity(0.2)
                          : purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isHighlighted ? Colors.white : purple,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Price ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    period,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),

          // ── Features ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: features
                  .map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: isHighlighted ? purple : Colors.green,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(f, style: const TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
