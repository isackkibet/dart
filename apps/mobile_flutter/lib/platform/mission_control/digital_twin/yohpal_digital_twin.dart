import '../health/enterprise_health.dart';

class YohPalDigitalTwin {
  final List<EnterpriseHealth> modules;
  final DateTime lastUpdated;

  const YohPalDigitalTwin({
    required this.modules,
    required this.lastUpdated,
  });

  double get ecosystemAvailability {
    if (modules.isEmpty) return 0;
    return modules.map((m) => m.availability).reduce((a, b) => a + b) /
        modules.length;
  }

  int get totalActiveUsers =>
      modules.fold(0, (sum, m) => sum + m.activeUsers);

  int get totalIncidents =>
      modules.fold(0, (sum, m) => sum + m.incidents);

  List<EnterpriseHealth> get criticalModules =>
      modules.where((m) => m.status == HealthStatus.critical).toList();

  List<EnterpriseHealth> get warningModules =>
      modules.where((m) => m.status == HealthStatus.warning).toList();

  HealthStatus get ecosystemStatus {
    if (modules.any((m) => m.status == HealthStatus.critical)) {
      return HealthStatus.critical;
    }
    if (modules.any((m) => m.status == HealthStatus.warning)) {
      return HealthStatus.warning;
    }
    return HealthStatus.healthy;
  }

  EnterpriseHealth? moduleHealth(String name) {
    try {
      return modules.firstWhere((m) => m.module == name);
    } catch (_) {
      return null;
    }
  }
}
