class PaidMessage {
  const PaidMessage({
    required this.id,
    required this.sessionId,
    required this.creatorId,
    required this.senderId,
    required this.message,
    required this.amount,
    required this.currency,
    required this.priorityRank,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String creatorId;
  final String senderId;
  final String message;
  final double amount;
  final String currency;
  final int priorityRank;
  final DateTime? createdAt;

  factory PaidMessage.fromMap(String id, Map<String, dynamic> map) {
    return PaidMessage(
      id: id,
      sessionId: map['sessionId']?.toString() ?? '',
      creatorId: map['creatorId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currency: map['currency']?.toString() ?? 'KES',
      priorityRank: (map['priorityRank'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
