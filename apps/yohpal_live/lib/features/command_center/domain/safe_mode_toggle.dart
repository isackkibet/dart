class SafeModeToggle {
  const SafeModeToggle({
    required this.id,
    required this.key,
    required this.label,
    required this.enabled,
    required this.reason,
    required this.updatedAt,
  });

  final String id;
  final String key;
  final String label;
  final bool enabled;
  final String reason;
  final DateTime? updatedAt;

  factory SafeModeToggle.fromMap(String id, Map<String, dynamic> map) {
    return SafeModeToggle(
      id: id,
      key: map['key']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      enabled: map['enabled'] == true,
      reason: map['reason']?.toString() ?? '',
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
