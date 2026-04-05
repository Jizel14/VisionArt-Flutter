class SubscriptionModel {
  final String plan;           // 'free' | 'pro'
  final String status;         // 'active' | 'inactive' | 'past_due' | 'canceled'
  final int generationsUsedThisMonth;
  final int? quotaLimit;       // null = unlimited (pro)
  final DateTime? currentPeriodEnd;
  final DateTime? quotaResetAt;

  const SubscriptionModel({
    required this.plan,
    required this.status,
    required this.generationsUsedThisMonth,
    this.quotaLimit,
    this.currentPeriodEnd,
    this.quotaResetAt,
  });

  bool get isPro => plan == 'pro';
  bool get isFree => plan == 'free';
  bool get isActive => status == 'active';

  int get generationsRemaining {
    if (isPro || quotaLimit == null) return -1; // unlimited
    return (quotaLimit! - generationsUsedThisMonth).clamp(0, quotaLimit!);
  }

  bool get quotaExceeded =>
      isFree && quotaLimit != null && generationsUsedThisMonth >= quotaLimit!;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      plan: json['plan'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      generationsUsedThisMonth:
          json['generationsUsedThisMonth'] as int? ?? 0,
      quotaLimit: json['quotaLimit'] as int?,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.tryParse(json['currentPeriodEnd'] as String)
          : null,
      quotaResetAt: json['quotaResetAt'] != null
          ? DateTime.tryParse(json['quotaResetAt'] as String)
          : null,
    );
  }

  /// Default free-tier subscription (used before first API call)
  factory SubscriptionModel.defaultFree() {
    final nextMonth = DateTime.now();
    return SubscriptionModel(
      plan: 'free',
      status: 'active',
      generationsUsedThisMonth: 0,
      quotaLimit: 10,
      quotaResetAt: DateTime(nextMonth.year, nextMonth.month + 1, 1),
    );
  }
}
