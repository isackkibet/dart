class PredictedDestinationModel {
  final String type;
  final String id;
  final double confidence;
  final Map<String, dynamic> metadata;

  const PredictedDestinationModel({
    required this.type,
    required this.id,
    required this.confidence,
    this.metadata = const {},
  });
}
