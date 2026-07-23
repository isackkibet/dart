class SessionReplay {
  const SessionReplay({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.status,
    required this.durationSeconds,
    required this.storageRef,
    required this.thumbnailRef,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String status; // pending, processing, ready, failed
  final int durationSeconds;
  final String storageRef;
  final String thumbnailRef;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SessionReplay.fromMap(String id, Map<String, dynamic> map) {
    return SessionReplay(
      id: id,
      sessionId: map['sessionId']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      storageRef: map['storageRef']?.toString() ?? '',
      thumbnailRef: map['thumbnailRef']?.toString() ?? '',
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    }
    return '${minutes}m ${seconds}s';
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
