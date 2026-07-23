class PipMetrics {
  final Duration duration;
  final bool playbackInterrupted;
  final bool appCrash;
  final double batteryDelta;
  final bool restoredSuccessfully;
  const PipMetrics({
    required this.duration,
    required this.playbackInterrupted,
    required this.appCrash,
    required this.batteryDelta,
    required this.restoredSuccessfully,
  });
}
