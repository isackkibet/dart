class AutonomyPolicy {
  const AutonomyPolicy({
    required this.id,
    required this.creatorId,
    required this.domain,
    required this.name,
    required this.description,
    required this.mode,
    required this.enabled,
    required this.maxActionsPerHour,
    required this.requiresApproval,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String creatorId;
  final String domain; // growth, monetisation, scaling, moderation
  final String name;
  final String description;
  final String mode; // inform, assisted, controlled, disabled
  final bool enabled;
  final int maxActionsPerHour;
  final bool requiresApproval;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AutonomyPolicy.fromMap(String id, Map<String, dynamic> map) {
    return AutonomyPolicy(
      id: id,
      creatorId: map['creatorId']?.toString() ?? '',
      domain: map['domain']?.toString() ?? 'growth',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      mode: map['mode']?.toString() ?? 'assisted',
      enabled: map['enabled'] == true,
      maxActionsPerHour: (map['maxActionsPerHour'] as num?)?.toInt() ?? 3,
      requiresApproval: map['requiresApproval'] != false,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'domain': domain,
      'name': name,
      'description': description,
      'mode': mode,
      'enabled': enabled,
      'maxActionsPerHour': maxActionsPerHour,
      'requiresApproval': requiresApproval,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
