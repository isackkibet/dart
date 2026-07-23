class WalletBalanceModel {
  final String userId;
  final num available;
  final num pending;
  final num lifetime;
  final String currency;

  const WalletBalanceModel({
    required this.userId,
    required this.available,
    required this.pending,
    required this.lifetime,
    required this.currency,
  });

  factory WalletBalanceModel.fromMap(Map<String, dynamic> map) {
    return WalletBalanceModel(
      userId: map['userId'] ?? '',
      available: map['available'] ?? 0,
      pending: map['pending'] ?? 0,
      lifetime: map['lifetime'] ?? 0,
      currency: map['currency'] ?? 'KES',
    );
  }
}
