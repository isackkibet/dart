class YohPalVideoMetrics {
  final String videoId;
  final int startupMs;
  final int bufferingMs;
  final int droppedFrames;
  final int memoryMb;
  final DateTime recordedAt;

  const YohPalVideoMetrics({
    required this.videoId,
    required this.startupMs,
    required this.bufferingMs,
    required this.droppedFrames,
    required this.memoryMb,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'startupMs': startupMs,
        'bufferingMs': bufferingMs,
        'droppedFrames': droppedFrames,
        'memoryMb': memoryMb,
        'recordedAt': recordedAt.toIso8601String(),
      };
}
