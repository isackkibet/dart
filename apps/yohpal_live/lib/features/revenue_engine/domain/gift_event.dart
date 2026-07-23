class GiftEvent {
  const GiftEvent({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.senderId,
    required this.giftType,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String senderId;
  final String giftType;
  final double amount;
  final String currency;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'creatorId': creatorId,
      'senderId': senderId,
      'giftType': giftType,
      'amount': amount,
      'currency': currency,
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  factory GiftEvent.fromMap(String id, Map<String, dynamic> map) {
    return GiftEvent(
      id: id,
      sessionId: map['sessionId']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      giftType: map['giftType']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency']?.toString() ?? 'KES',
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
