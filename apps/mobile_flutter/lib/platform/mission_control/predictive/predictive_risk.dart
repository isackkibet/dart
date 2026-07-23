class PredictiveRisk {
  final String module;
  final String risk;
  final double probability;
  final String recommendation;

  const PredictiveRisk({
    required this.module,
    required this.risk,
    required this.probability,
    required this.recommendation,
  });

  bool get isHighProbability => probability >= 0.7;
  bool get isMediumProbability => probability >= 0.4 && probability < 0.7;
  bool get isLowProbability => probability < 0.4;

  String get probabilityLabel {
    if (isHighProbability) return 'High';
    if (isMediumProbability) return 'Medium';
    return 'Low';
  }
}

// Well-known risk detectors used by the predictive engine.
class PredictiveRiskDetector {
  static PredictiveRisk? liveLatencyRising(double latencyMs) {
    if (latencyMs <= 2000) return null;
    return PredictiveRisk(
      module: 'live',
      risk: 'Live latency increasing (${latencyMs.toStringAsFixed(0)} ms)',
      probability: (latencyMs / 4000).clamp(0.0, 1.0),
      recommendation: 'Recommend scaling Cloud Run instances',
    );
  }

  static PredictiveRisk? walletFailuresRising(double failureRate) {
    if (failureRate <= 0.01) return null;
    return PredictiveRisk(
      module: 'wallet',
      risk: 'Wallet transaction failure rate elevated (${(failureRate * 100).toStringAsFixed(1)}%)',
      probability: (failureRate * 10).clamp(0.0, 1.0),
      recommendation: 'Pause payouts and investigate payment gateway',
    );
  }

  static PredictiveRisk? aiLatencyRising(double latencyMs) {
    if (latencyMs <= 2000) return null;
    return PredictiveRisk(
      module: 'brain',
      risk: 'AI response latency rising (${latencyMs.toStringAsFixed(0)} ms)',
      probability: (latencyMs / 5000).clamp(0.0, 1.0),
      recommendation: 'Scale YohPal Brain Cloud Function workers',
    );
  }

  static PredictiveRisk? ffmpegQueueBuilding(int queueDepth) {
    if (queueDepth <= 10) return null;
    return PredictiveRisk(
      module: 'live',
      risk: 'FFmpeg processing queue building ($queueDepth jobs)',
      probability: (queueDepth / 50).clamp(0.0, 1.0),
      recommendation: 'Increase Cloud Run FFmpeg worker instances',
    );
  }

  static PredictiveRisk? firestoreReadsSpike(int readsPerSecond) {
    if (readsPerSecond <= 5000) return null;
    return PredictiveRisk(
      module: 'platform',
      risk: 'Firestore read rate elevated ($readsPerSecond/s)',
      probability: (readsPerSecond / 20000).clamp(0.0, 1.0),
      recommendation: 'Increase client-side cache TTL and review hot documents',
    );
  }
}
