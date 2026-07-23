class AutoResponseRule {
  const AutoResponseRule({
    required this.id,
    required this.name,
    required this.eventType,
    required this.conditionMetric,
    required this.conditionOperator,
    required this.conditionValue,
    required this.actionType,
    required this.enabled,
    required this.requiresApproval,
  });

  final String id;
  final String name;
  final String eventType;
  final String conditionMetric;
  final String conditionOperator;
  final double conditionValue;
  final String actionType;
  final bool enabled;
  final bool requiresApproval;

  factory AutoResponseRule.fromMap(String id, Map<String, dynamic> map) {
    return AutoResponseRule(
      id: id,
      name: map['name']?.toString() ?? '',
      eventType: map['eventType']?.toString() ?? '',
      conditionMetric: map['conditionMetric']?.toString() ?? '',
      conditionOperator: map['conditionOperator']?.toString() ?? '>',
      conditionValue: (map['conditionValue'] as num?)?.toDouble() ?? 0,
      actionType: map['actionType']?.toString() ?? '',
      enabled: map['enabled'] == true,
      requiresApproval: map['requiresApproval'] != false,
    );
  }
}
