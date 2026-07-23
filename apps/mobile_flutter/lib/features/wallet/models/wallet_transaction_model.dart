class WalletTransactionModel {
  final String id;
  final String userId;
  final String type;
  final num amount;
  final String currency;
  final String status;
  final DateTime createdAt;

  const WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromMap(Map<String, dynamic> map) {
    return WalletTransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      amount: map['amount'] ?? 0,
      currency: map['currency'] ?? 'KES',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
