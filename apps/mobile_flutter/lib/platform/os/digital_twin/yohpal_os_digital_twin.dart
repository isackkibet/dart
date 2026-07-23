class YohPalModuleState {
  final String module;
  final String health;
  final double availability;
  final double latencyMs;
  final int activeUsers;
  final int openIncidents;

  const YohPalModuleState({
    required this.module,
    required this.health,
    required this.availability,
    required this.latencyMs,
    required this.activeUsers,
    required this.openIncidents,
  });
}

class YohPalOSDigitalTwin {
  final List<YohPalModuleState> modules;
  final DateTime updatedAt;

  const YohPalOSDigitalTwin({
    required this.modules,
    required this.updatedAt,
  });

  double get ecosystemAvailability {
    if (modules.isEmpty) return 0;
    return modules.map((m) => m.availability).reduce((a, b) => a + b) /
        modules.length;
  }

  bool get hasCriticalIncident =>
      modules.any((m) => m.health == 'critical');
}
