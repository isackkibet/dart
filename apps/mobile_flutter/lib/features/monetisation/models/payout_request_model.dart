class PayoutRequestModel {
  final String id;
  final String creatorId;
  final num amount;
  final String currency;
  final String status;
  final DateTime createdAt;

  const PayoutRequestModel({
    required this.id,
    required this.creatorId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory PayoutRequestModel.fromMap(Map<String, dynamic> map) {
    return PayoutRequestModel(
      id: map['id'] ?? '',
      creatorId: map['creatorId'] ?? '',
      amount: map['amount'] ?? 0,
      currency: map['currency'] ?? 'KES',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
