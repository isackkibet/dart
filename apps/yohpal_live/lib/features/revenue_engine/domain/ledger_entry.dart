class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.ownerId,
    required this.ownerType,
    required this.entryType,
    required this.direction,
    required this.referenceType,
    required this.referenceId,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String ownerType;
  final String entryType;
  final String direction;
  final String referenceType;
  final String referenceId;
  final double amount;
  final String currency;
  final DateTime? createdAt;

  factory LedgerEntry.fromMap(String id, Map<String, dynamic> map) {
    return LedgerEntry(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      ownerType: map['ownerType']?.toString() ?? '',
      entryType: map['entryType']?.toString() ?? '',
      direction: map['direction']?.toString() ?? '',
      referenceType: map['referenceType']?.toString() ?? '',
      referenceId: map['referenceId']?.toString() ?? '',
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
