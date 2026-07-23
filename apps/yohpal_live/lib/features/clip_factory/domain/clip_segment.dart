class ClipSegment {
  const ClipSegment({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.title,
    required this.startOffsetSeconds,
    required this.endOffsetSeconds,
    required this.triggerEventType,
    required this.triggerScore,
    required this.suggestedPlatforms,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String title;
  final int startOffsetSeconds;
  final int endOffsetSeconds;
  final String triggerEventType; // gift_spike, paid_message, peak_viewers, teaser_conversion, autonomy_decision
  final double triggerScore;
  final List<String> suggestedPlatforms;
  final String status; // proposed, approved, rejected, exporting, exported, distributed

  final DateTime? createdAt;

  int get durationSeconds => endOffsetSeconds - startOffsetSeconds;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  factory ClipSegment.fromMap(String id, Map<String, dynamic> map) {
    return ClipSegment(
      id: id,
      sessionId: map['sessionId']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      startOffsetSeconds: (map['startOffsetSeconds'] as num?)?.toInt() ?? 0,
      endOffsetSeconds: (map['endOffsetSeconds'] as num?)?.toInt() ?? 0,
      triggerEventType: map['triggerEventType']?.toString() ?? 'peak_viewers',
      triggerScore: (map['triggerScore'] as num?)?.toDouble() ?? 0,
      suggestedPlatforms: List<String>.from(
        map['suggestedPlatforms'] as List? ?? [],
      ),
      status: map['status']?.toString() ?? 'proposed',
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
