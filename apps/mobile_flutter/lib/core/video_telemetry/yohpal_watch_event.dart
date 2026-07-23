enum YohPalWatchEventType {
  impression,
  play,
  pause,
  skip,
  complete,
  replay,
  like,
  comment,
  share,
  bufferStart,
  bufferEnd,
  startupMeasured,
  error,
}

class YohPalWatchEvent {
  final String eventId;
  final String userId;
  final String videoId;
  final YohPalWatchEventType type;
  final int positionMs;
  final int durationMs;
  final int? startupMs;
  final int? bufferingMs;
  final String? errorCode;
  final DateTime createdAt;

  const YohPalWatchEvent({
    required this.eventId,
    required this.userId,
    required this.videoId,
    required this.type,
    required this.positionMs,
    required this.durationMs,
    this.startupMs,
    this.bufferingMs,
    this.errorCode,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'userId': userId,
      'videoId': videoId,
      'type': type.name,
      'positionMs': positionMs,
      'durationMs': durationMs,
      'startupMs': startupMs,
      'bufferingMs': bufferingMs,
      'errorCode': errorCode,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
