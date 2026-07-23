class PlaybackDiagnosticModel {
  final String videoId;
  final String userId;
  final int timeToFirstFrameMs;
  final bool preloadHit;
  final String sourceUrlType;
  final String networkType;
  final String? playbackError;

  const PlaybackDiagnosticModel({
    required this.videoId,
    required this.userId,
    required this.timeToFirstFrameMs,
    required this.preloadHit,
    required this.sourceUrlType,
    required this.networkType,
    this.playbackError,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'userId': userId,
      'timeToFirstFrameMs': timeToFirstFrameMs,
      'preloadHit': preloadHit,
      'sourceUrlType': sourceUrlType,
      'networkType': networkType,
      'playbackError': playbackError,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
