class YohPalVideoPerformanceTracker {
  final String videoId;
  final Stopwatch _startupWatch = Stopwatch();
  final Stopwatch _bufferingWatch = Stopwatch();
  int totalBufferingMs = 0;

  YohPalVideoPerformanceTracker({required this.videoId});

  void markLoadStarted() {
    _startupWatch
      ..reset()
      ..start();
  }

  int markFirstFrameRendered() {
    _startupWatch.stop();
    return _startupWatch.elapsedMilliseconds;
  }

  void markBufferStart() {
    _bufferingWatch
      ..reset()
      ..start();
  }

  int markBufferEnd() {
    _bufferingWatch.stop();
    final ms = _bufferingWatch.elapsedMilliseconds;
    totalBufferingMs += ms;
    return ms;
  }
}
