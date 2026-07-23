class FloatingPilotMetrics {
  final String uid;
  final String module;
  final String entityId;
  final Duration duration;
  final int actionClicks;
  final int conversions;
  final num revenue;
  final bool crashed;
  final double batteryDelta;
  final DateTime createdAt;
  const FloatingPilotMetrics({
    required this.uid,
    required this.module,
    required this.entityId,
    required this.duration,
    required this.actionClicks,
    required this.conversions,
    required this.revenue,
    required this.crashed,
    required this.batteryDelta,
    required this.createdAt,
  });
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'module': module,
      'entityId': entityId,
      'durationMs': duration.inMilliseconds,
      'actionClicks': actionClicks,
      'conversions': conversions,
      'revenue': revenue,
      'crashed': crashed,
      'batteryDelta': batteryDelta,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
