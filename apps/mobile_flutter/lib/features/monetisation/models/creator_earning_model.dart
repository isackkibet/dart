class CreatorEarningModel {
  final String id;
  final String creatorId;
  final String source;
  final String sourceId;
  final num amount;
  final String currency;
  final String status;
  final DateTime createdAt;

  const CreatorEarningModel({
    required this.id,
    required this.creatorId,
    required this.source,
    required this.sourceId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory CreatorEarningModel.fromMap(Map<String, dynamic> map) {
    return CreatorEarningModel(
      id: map['id'] ?? '',
      creatorId: map['creatorId'] ?? '',
      source: map['source'] ?? '',
      sourceId: map['sourceId'] ?? '',
      amount: map['amount'] ?? 0,
      currency: map['currency'] ?? 'KES',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
