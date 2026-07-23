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
}
