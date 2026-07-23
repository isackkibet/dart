class TrafficEvent {
  const TrafficEvent({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.sourcePlatform,
    required this.eventType,
    required this.anonymousId,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String sourcePlatform;
  final String eventType;
  final String anonymousId;
  final String? userId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'creatorId': creatorId,
      'sourcePlatform': sourcePlatform,
      'eventType': eventType,
      'anonymousId': anonymousId,
      'userId': userId,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
