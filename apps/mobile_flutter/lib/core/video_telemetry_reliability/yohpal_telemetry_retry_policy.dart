class YohPalTelemetryRetryPolicy {
  final int maxRetryCount;

  const YohPalTelemetryRetryPolicy({this.maxRetryCount = 10});

  bool canRetry(int retryCount) => retryCount < maxRetryCount;

  Duration delayForRetry(int retryCount) {
    if (retryCount <= 1) return const Duration(seconds: 5);
    if (retryCount <= 3) return const Duration(seconds: 30);
    if (retryCount <= 6) return const Duration(minutes: 2);
    return const Duration(minutes: 10);
  }
}
