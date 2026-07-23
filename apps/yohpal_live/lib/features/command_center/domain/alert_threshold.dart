class AlertThreshold {
  const AlertThreshold({
    required this.id,
    required this.metric,
    required this.operator,
    required this.value,
    required this.severity,
    required this.enabled,
  });

  final String id;
  final String metric;
  final String operator;
  final double value;
  final String severity;
  final bool enabled;

  factory AlertThreshold.fromMap(String id, Map<String, dynamic> map) {
    return AlertThreshold(
      id: id,
      metric: map['metric']?.toString() ?? '',
      operator: map['operator']?.toString() ?? '>',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      severity: map['severity']?.toString() ?? 'p3',
      enabled: map['enabled'] == true,
    );
  }
}
