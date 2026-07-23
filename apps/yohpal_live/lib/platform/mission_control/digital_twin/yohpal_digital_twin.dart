import '../health/enterprise_health.dart';

class YohPalDigitalTwin {
  final List<EnterpriseHealth> modules;
  const YohPalDigitalTwin({
    required this.modules,
  });
  double get ecosystemHealth {
    if (modules.isEmpty) return 0;
    return modules
            .map((m) => m.availability)
            .reduce((a, b) => a + b) /
        modules.length;
  }
}
