class WalletSummary {
  const WalletSummary({
    required this.creatorId,
    required this.currency,
    required this.totalCredits,
    required this.totalDebits,
    required this.availableBalance,
    required this.pendingBalance,
    required this.giftRevenue,
    required this.paidMessageRevenue,
  });

  final String creatorId;
  final String currency;
  final double totalCredits;
  final double totalDebits;
  final double availableBalance;
  final double pendingBalance;
  final double giftRevenue;
  final double paidMessageRevenue;

  factory WalletSummary.fromMap(Map<String, dynamic> map) {
    return WalletSummary(
      creatorId: map['creatorId']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'KES',
      totalCredits: (map['totalCredits'] as num?)?.toDouble() ?? 0,
      totalDebits: (map['totalDebits'] as num?)?.toDouble() ?? 0,
      availableBalance: (map['availableBalance'] as num?)?.toDouble() ?? 0,
      pendingBalance: (map['pendingBalance'] as num?)?.toDouble() ?? 0,
      giftRevenue: (map['giftRevenue'] as num?)?.toDouble() ?? 0,
      paidMessageRevenue:
          (map['paidMessageRevenue'] as num?)?.toDouble() ?? 0,
    );
  }
}
