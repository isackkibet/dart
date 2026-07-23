class AdCampaign {
  const AdCampaign({
    required this.id,
    required this.advertiserId,
    required this.title,
    required this.status,
    required this.budgetCents,
    required this.spentCents,
    required this.cpmCents,
    required this.creativeType,
    required this.creativeRef,
    required this.ctaLabel,
    required this.ctaUrl,
    required this.impressionCount,
    required this.clickCount,
    this.targetingTags = const [],
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  final String id;
  final String advertiserId;
  final String title;

  /// 'draft' | 'active' | 'paused' | 'completed'
  final String status;

  /// Budget and spend in cents (e.g. 500 = $5.00)
  final int budgetCents;
  final int spentCents;

  /// Cost per 1000 impressions in cents
  final int cpmCents;

  /// 'banner' | 'overlay' | 'sponsored_poll'
  final String creativeType;
  final String creativeRef;
  final String ctaLabel;
  final String ctaUrl;

  final List<String> targetingTags;
  final int impressionCount;
  final int clickCount;

  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  // ── Computed ──────────────────────────────────────────────────────────────

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isDraft => status == 'draft';
  bool get isCompleted => status == 'completed';

  int get remainingBudgetCents => (budgetCents - spentCents).clamp(0, budgetCents);

  double get budgetUsedPercent =>
      budgetCents == 0 ? 0.0 : (spentCents / budgetCents * 100).clamp(0.0, 100.0);

  /// Click-through rate as a percentage (0–100).
  double get ctr => impressionCount == 0
      ? 0.0
      : (clickCount / impressionCount * 100).clamp(0.0, 100.0);

  String get statusLabel => switch (status) {
        'draft' => 'Draft',
        'active' => 'Active',
        'paused' => 'Paused',
        'completed' => 'Completed',
        _ => status,
      };

  String get creativeTypeLabel => switch (creativeType) {
        'banner' => 'Banner',
        'overlay' => 'Overlay',
        'sponsored_poll' => 'Sponsored Poll',
        _ => creativeType,
      };

  String get budgetDisplay =>
      '\$${(budgetCents / 100).toStringAsFixed(2)}';

  String get spentDisplay =>
      '\$${(spentCents / 100).toStringAsFixed(2)}';

  factory AdCampaign.fromMap(String id, Map<String, dynamic> map) {
    final rawTags = map['targetingTags'];
    final List<String> tags;
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    } else {
      tags = const [];
    }

    return AdCampaign(
      id: id,
      advertiserId: map['advertiserId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      budgetCents: (map['budgetCents'] as num?)?.toInt() ?? 0,
      spentCents: (map['spentCents'] as num?)?.toInt() ?? 0,
      cpmCents: (map['cpmCents'] as num?)?.toInt() ?? 0,
      creativeType: map['creativeType']?.toString() ?? 'banner',
      creativeRef: map['creativeRef']?.toString() ?? '',
      ctaLabel: map['ctaLabel']?.toString() ?? 'Learn More',
      ctaUrl: map['ctaUrl']?.toString() ?? '',
      targetingTags: tags,
      impressionCount: (map['impressionCount'] as num?)?.toInt() ?? 0,
      clickCount: (map['clickCount'] as num?)?.toInt() ?? 0,
      startDate: _readDate(map['startDate']),
      endDate: _readDate(map['endDate']),
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
