class LiveGiftModel {
  final String id;
  final String sessionId;
  final String senderUserId;
  final String creatorId;
  final String giftType;
  final int amount;
  final String currency;
  final DateTime createdAt;

  const LiveGiftModel({
    required this.id,
    required this.sessionId,
    required this.senderUserId,
    required this.creatorId,
    required this.giftType,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory LiveGiftModel.fromMap(Map<String, dynamic> map) {
    return LiveGiftModel(
      id: map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      senderUserId: map['senderUserId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      giftType: map['giftType'] ?? '',
      amount: map['amount'] ?? 0,
      currency: map['currency'] ?? 'KES',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'senderUserId': senderUserId,
      'creatorId': creatorId,
      'giftType': giftType,
      'amount': amount,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
