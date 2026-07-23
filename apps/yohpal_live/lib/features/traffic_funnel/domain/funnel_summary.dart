class FunnelSummary {
  const FunnelSummary({
    required this.sessionId,
    required this.totalEvents,
    required this.totalConversions,
    required this.totalRevenue,
    required this.byPlatform,
    required this.byEventType,
    required this.byConversionType,
  });

  final String sessionId;
  final int totalEvents;
  final int totalConversions;
  final double totalRevenue;
  final Map<String, int> byPlatform;
  final Map<String, int> byEventType;
  final Map<String, int> byConversionType;

  factory FunnelSummary.fromMap(Map<String, dynamic> map) {
    return FunnelSummary(
      sessionId: map['sessionId']?.toString() ?? '',
      totalEvents: (map['totalEvents'] as num?)?.toInt() ?? 0,
      totalConversions: (map['totalConversions'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0,
      byPlatform: _readStringIntMap(map['byPlatform']),
      byEventType: _readStringIntMap(map['byEventType']),
      byConversionType: _readStringIntMap(map['byConversionType']),
    );
  }

  static Map<String, int> _readStringIntMap(Object? value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(
        key.toString(),
        (item as num?)?.toInt() ?? 0,
      ),
    );
  }
}
