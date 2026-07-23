class ConnectorHealth {
  const ConnectorHealth({
    required this.connectorId,
    required this.platform,
    required this.status,
    required this.checkedAt,
    this.latencyMs,
    this.errorMessage,
  });

  final String connectorId;
  final String platform;

  /// Health state: healthy | degraded | expired | failed
  final String status;

  final DateTime? checkedAt;
  final int? latencyMs;
  final String? errorMessage;

  bool get isHealthy => status == 'healthy';

  factory ConnectorHealth.fromMap(Map<String, dynamic> map) {
    return ConnectorHealth(
      connectorId: map['connectorId']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
      status: map['status']?.toString() ?? 'failed',
      checkedAt: _readDate(map['checkedAt']),
      latencyMs: (map['latencyMs'] as num?)?.toInt(),
      errorMessage: map['errorMessage']?.toString(),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
