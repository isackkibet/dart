class LiveDestination {
  const LiveDestination({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.platform,
    required this.destinationName,
    required this.streamMode,
    required this.status,
    required this.ctaEnabled,
    required this.delaySeconds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String platform;
  final String destinationName;
  final String streamMode;
  final String status;
  final bool ctaEnabled;
  final int delaySeconds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LiveDestination.fromMap(String id, Map<String, dynamic> map) {
    return LiveDestination(
      id: id,
      sessionId: map['sessionId']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
      destinationName: map['destinationName']?.toString() ?? '',
      streamMode: map['streamMode']?.toString() ?? 'teaser',
      status: map['status']?.toString() ?? 'enabled',
      ctaEnabled: map['ctaEnabled'] == true,
      delaySeconds: (map['delaySeconds'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'creatorId': creatorId,
      'platform': platform,
      'destinationName': destinationName,
      'streamMode': streamMode,
      'status': status,
      'ctaEnabled': ctaEnabled,
      'delaySeconds': delaySeconds,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
