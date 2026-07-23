class YohPalVideoTelemetryEvent {
  final String videoId;
  final int startupMs;
  final int bufferingMs;
  final int droppedFrames;
  final int memoryMb;
  final DateTime timestamp;

  const YohPalVideoTelemetryEvent({
    required this.videoId,
    required this.startupMs,
    required this.bufferingMs,
    required this.droppedFrames,
    required this.memoryMb,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'startupMs': startupMs,
        'bufferingMs': bufferingMs,
        'droppedFrames': droppedFrames,
        'memoryMb': memoryMb,
        'timestamp': timestamp.toIso8601String(),
      };
}

class YohPalVideoTelemetryService {
  final List<YohPalVideoTelemetryEvent> _events = [];

  void record(YohPalVideoTelemetryEvent event) => _events.add(event);

  List<Map<String, dynamic>> exportJson() =>
      _events.map((e) => e.toJson()).toList();

  void clear() => _events.clear();
}
