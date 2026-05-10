class LoyaltyTier {
  final int points;
  final int freeMonths;
  final String label;

  const LoyaltyTier({
    required this.points,
    required this.freeMonths,
    required this.label,
  });

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) {
    return LoyaltyTier(
      points: (json['points'] as num?)?.toInt() ?? 0,
      freeMonths: (json['freeMonths'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
    );
  }
}

class LoyaltyEvent {
  final String id;
  final String type;
  final int delta;
  final DateTime createdAt;

  const LoyaltyEvent({
    required this.id,
    required this.type,
    required this.delta,
    required this.createdAt,
  });

  factory LoyaltyEvent.fromJson(Map<String, dynamic> json) {
    return LoyaltyEvent(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      delta: (json['delta'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class LoyaltyMe {
  final int balance;
  final List<LoyaltyTier> tiers;
  final List<LoyaltyEvent> recentEvents;

  const LoyaltyMe({
    required this.balance,
    required this.tiers,
    required this.recentEvents,
  });

  factory LoyaltyMe.fromJson(Map<String, dynamic> json) {
    final tiers = (json['tiers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LoyaltyTier.fromJson(e.cast<String, dynamic>()))
        .toList();
    final events = (json['recentEvents'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => LoyaltyEvent.fromJson(e.cast<String, dynamic>()))
        .toList();
    return LoyaltyMe(
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      tiers: tiers,
      recentEvents: events,
    );
  }
}

