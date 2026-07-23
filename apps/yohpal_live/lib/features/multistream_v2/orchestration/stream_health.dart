class StreamHealth {
  const StreamHealth({
    required this.sessionId,
    required this.status,
    required this.ingestStatus,
    required this.activeDestinations,
    required this.failedDestinations,
    required this.bitrateKbps,
    required this.latencyMs,
    required this.lastHeartbeatAt,
  });

  final String sessionId;
  final String status;
  final String ingestStatus;
  final int activeDestinations;
  final int failedDestinations;
  final int bitrateKbps;
  final int latencyMs;
  final DateTime? lastHeartbeatAt;

  factory StreamHealth.fromMap(Map<String, dynamic> map) {
    return StreamHealth(
      sessionId: map['sessionId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'unknown',
      ingestStatus: map['ingestStatus']?.toString() ?? 'unknown',
      activeDestinations: (map['activeDestinations'] as num?)?.toInt() ?? 0,
      failedDestinations: (map['failedDestinations'] as num?)?.toInt() ?? 0,
      bitrateKbps: (map['bitrateKbps'] as num?)?.toInt() ?? 0,
      latencyMs: (map['latencyMs'] as num?)?.toInt() ?? 0,
      lastHeartbeatAt: _readDate(map['lastHeartbeatAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'status': status,
      'ingestStatus': ingestStatus,
      'activeDestinations': activeDestinations,
      'failedDestinations': failedDestinations,
      'bitrateKbps': bitrateKbps,
      'latencyMs': latencyMs,
      'lastHeartbeatAt': lastHeartbeatAt?.toUtc().toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
