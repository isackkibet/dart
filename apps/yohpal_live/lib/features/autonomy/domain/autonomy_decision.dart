class AutonomyDecision {
  const AutonomyDecision({
    required this.id,
    required this.creatorId,
    required this.sessionId,
    required this.domain,
    required this.recommendation,
    required this.reason,
    required this.confidence,
    required this.status,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String? sessionId;
  final String domain;
  final String recommendation;
  final String reason;
  final double confidence;
  final String status; // proposed, approved, rejected, executed
  final String actionType;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AutonomyDecision.fromMap(String id, Map<String, dynamic> map) {
    return AutonomyDecision(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      sessionId: map['sessionId']?.toString(),
      domain: map['domain']?.toString() ?? 'growth',
      recommendation: map['recommendation']?.toString() ?? '',
      reason: map['reason']?.toString() ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'proposed',
      actionType: map['actionType']?.toString() ?? 'recommendation',
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
