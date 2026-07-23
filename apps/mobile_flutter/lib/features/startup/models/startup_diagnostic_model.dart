/// Cold-start timing for a single app launch, recorded by [YohPalBootstrap].
class StartupDiagnosticModel {
  final int appStartMs;
  final int feedWarmupMs;
  final int? firstVideoReadyMs;
  final bool warmupSuccess;

  const StartupDiagnosticModel({
    required this.appStartMs,
    required this.feedWarmupMs,
    required this.firstVideoReadyMs,
    required this.warmupSuccess,
  });

  Map<String, dynamic> toMap() {
    return {
      'appStartMs': appStartMs,
      'feedWarmupMs': feedWarmupMs,
      'firstVideoReadyMs': firstVideoReadyMs,
      'warmupSuccess': warmupSuccess,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
