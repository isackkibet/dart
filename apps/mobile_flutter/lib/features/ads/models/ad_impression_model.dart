class AdImpressionModel {
  final String id;
  final String campaignId;
  final String userId;
  final String type;
  final num cost;
  final DateTime createdAt;

  const AdImpressionModel({
    required this.id,
    required this.campaignId,
    required this.userId,
    required this.type,
    required this.cost,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaignId': campaignId,
      'userId': userId,
      'type': type,
      'cost': cost,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
