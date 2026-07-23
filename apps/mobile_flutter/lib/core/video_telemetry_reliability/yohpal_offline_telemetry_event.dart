class YohPalOfflineTelemetryEvent {
  final String eventId;
  final String userId;
  final String videoId;
  final String type;
  final int positionMs;
  final int durationMs;
  final int retryCount;
  final DateTime createdAt;

  const YohPalOfflineTelemetryEvent({
    required this.eventId,
    required this.userId,
    required this.videoId,
    required this.type,
    required this.positionMs,
    required this.durationMs,
    required this.retryCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'userId': userId,
        'videoId': videoId,
        'type': type,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
      };

  factory YohPalOfflineTelemetryEvent.fromJson(Map<String, dynamic> json) {
    return YohPalOfflineTelemetryEvent(
      eventId: json['eventId'] as String,
      userId: json['userId'] as String,
      videoId: json['videoId'] as String,
      type: json['type'] as String,
      positionMs: json['positionMs'] as int,
      durationMs: json['durationMs'] as int,
      retryCount: (json['retryCount'] as int?) ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  YohPalOfflineTelemetryEvent incrementRetry() {
    return YohPalOfflineTelemetryEvent(
      eventId: eventId,
      userId: userId,
      videoId: videoId,
      type: type,
      positionMs: positionMs,
      durationMs: durationMs,
      retryCount: retryCount + 1,
      createdAt: createdAt,
    );
  }
}
