class YohPalEnterpriseEvent {
  final String id;
  final String module;
  final String type;
  final String severity;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const YohPalEnterpriseEvent({
    required this.id,
    required this.module,
    required this.type,
    required this.severity,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module': module,
      'type': type,
      'severity': severity,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
