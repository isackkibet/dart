enum HealthStatus { healthy, warning, critical }

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

  bool get isHealthy => status == HealthStatus.healthy;
  bool get needsAttention => status != HealthStatus.healthy;

  EnterpriseHealth copyWith({
    HealthStatus? status,
    double? availability,
    double? latencyMs,
    int? activeUsers,
    int? incidents,
  }) {
    return EnterpriseHealth(
      module: module,
      status: status ?? this.status,
      availability: availability ?? this.availability,
      latencyMs: latencyMs ?? this.latencyMs,
      activeUsers: activeUsers ?? this.activeUsers,
      incidents: incidents ?? this.incidents,
    );
  }
}
