enum HealthStatus {
  healthy,
  warning,
  critical,
}

class EnterpriseHealth {
  final String module;
  final HealthStatus status;
  final double availability;
  final double latencyMs;
  final int activeUsers;
  final int incidents;
  const EnterpriseHealth({
    required this.module,
    required this.status,
    required this.availability,
    required this.latencyMs,
    required this.activeUsers,
    required this.incidents,
  });
}
