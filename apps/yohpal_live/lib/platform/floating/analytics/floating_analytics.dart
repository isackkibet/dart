abstract class FloatingAnalytics {
  Future<void> trackStarted({
    required String module,
    required String entityId,
  });
  Future<void> trackAction({
    required String module,
    required String action,
    required Map<String, dynamic> metadata,
  });
  Future<void> trackStopped({
    required String module,
    required Duration duration,
  });
}
