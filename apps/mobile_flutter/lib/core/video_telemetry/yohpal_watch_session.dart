import 'yohpal_watch_event.dart';
import 'yohpal_video_performance_tracker.dart';
import 'yohpal_video_telemetry_client.dart';

class YohPalWatchSession {
  final String sessionId;
  final String userId;
  final String videoId;
  final int durationMs;
  final YohPalVideoTelemetryClient client;
  final YohPalVideoPerformanceTracker tracker;

  bool _started = false;
  bool _ended = false;

  YohPalWatchSession({
    required this.sessionId,
    required this.userId,
    required this.videoId,
    required this.durationMs,
    required this.client,
  }) : tracker = YohPalVideoPerformanceTracker(videoId: videoId);

  Future<void> impression(int positionMs) => _emit(
        YohPalWatchEventType.impression,
        positionMs: positionMs,
      );

  Future<void> play(int positionMs) async {
    _started = true;
    await _emit(YohPalWatchEventType.play, positionMs: positionMs);
  }

  Future<void> pause(int positionMs) =>
      _emit(YohPalWatchEventType.pause, positionMs: positionMs);

  Future<void> skip(int positionMs) async {
    _ended = true;
    await _emit(YohPalWatchEventType.skip, positionMs: positionMs);
    await client.flush();
  }

  Future<void> complete(int positionMs) async {
    _ended = true;
    await _emit(YohPalWatchEventType.complete, positionMs: positionMs);
    await client.flush();
  }

  Future<void> replay(int positionMs) =>
      _emit(YohPalWatchEventType.replay, positionMs: positionMs);

  Future<void> like(int positionMs) =>
      _emit(YohPalWatchEventType.like, positionMs: positionMs);

  Future<void> comment(int positionMs) =>
      _emit(YohPalWatchEventType.comment, positionMs: positionMs);

  Future<void> share(int positionMs) =>
      _emit(YohPalWatchEventType.share, positionMs: positionMs);

  Future<void> bufferStart(int positionMs) {
    tracker.markBufferStart();
    return _emit(YohPalWatchEventType.bufferStart, positionMs: positionMs);
  }

  Future<void> bufferEnd(int positionMs) {
    final bufferingMs = tracker.markBufferEnd();
    return _emit(
      YohPalWatchEventType.bufferEnd,
      positionMs: positionMs,
      bufferingMs: bufferingMs,
    );
  }

  Future<void> startupMeasured(int positionMs, int startupMs) =>
      _emit(
        YohPalWatchEventType.startupMeasured,
        positionMs: positionMs,
        startupMs: startupMs,
      );

  Future<void> error(int positionMs, String errorCode) =>
      _emit(
        YohPalWatchEventType.error,
        positionMs: positionMs,
        errorCode: errorCode,
      );

  bool get hasStarted => _started;
  bool get hasEnded => _ended;

  Future<void> _emit(
    YohPalWatchEventType type, {
    required int positionMs,
    int? startupMs,
    int? bufferingMs,
    String? errorCode,
  }) async {
    final event = YohPalWatchEvent(
      eventId: '${sessionId}_${type.name}_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      videoId: videoId,
      type: type,
      positionMs: positionMs,
      durationMs: durationMs,
      startupMs: startupMs,
      bufferingMs: bufferingMs,
      errorCode: errorCode,
      createdAt: DateTime.now().toUtc(),
    );
    await client.record(event);
  }
}
