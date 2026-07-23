import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/platform/mission_control/health/enterprise_health.dart';
import 'package:yohpal_live_v2/platform/mission_control/digital_twin/yohpal_digital_twin.dart';
import 'package:yohpal_live_v2/platform/mission_control/predictive/predictive_risk.dart';

EnterpriseHealth _module(
  String name, {
  HealthStatus status = HealthStatus.healthy,
  double availability = 99.9,
  double latencyMs = 100,
  int activeUsers = 1000,
  int incidents = 0,
}) =>
    EnterpriseHealth(
      module: name,
      status: status,
      availability: availability,
      latencyMs: latencyMs,
      activeUsers: activeUsers,
      incidents: incidents,
    );

void main() {
  group('EnterpriseHealth', () {
    test('isHealthy is true when status is healthy', () {
      expect(_module('live').isHealthy, true);
    });

    test('needsAttention is true when status is warning', () {
      expect(_module('live', status: HealthStatus.warning).needsAttention, true);
    });

    test('needsAttention is true when status is critical', () {
      expect(_module('live', status: HealthStatus.critical).needsAttention, true);
    });

    test('copyWith preserves module name', () {
      final h = _module('wallet').copyWith(status: HealthStatus.warning);
      expect(h.module, 'wallet');
      expect(h.status, HealthStatus.warning);
    });
  });

  group('YohPalDigitalTwin', () {
    test('ecosystemAvailability is mean of all module availabilities', () {
      final twin = YohPalDigitalTwin(
        modules: [
          _module('live', availability: 99.9),
          _module('hustle', availability: 99.7),
          _module('jobs', availability: 100.0),
        ],
        lastUpdated: DateTime.now(),
      );
      expect(twin.ecosystemAvailability, closeTo(99.866, 0.001));
    });

    test('ecosystemAvailability is 0 for empty module list', () {
      final twin = YohPalDigitalTwin(modules: [], lastUpdated: DateTime.now());
      expect(twin.ecosystemAvailability, 0);
    });

    test('totalActiveUsers sums across all modules', () {
      final twin = YohPalDigitalTwin(
        modules: [
          _module('live', activeUsers: 5000),
          _module('hustle', activeUsers: 2000),
        ],
        lastUpdated: DateTime.now(),
      );
      expect(twin.totalActiveUsers, 7000);
    });

    test('totalIncidents sums across all modules', () {
      final twin = YohPalDigitalTwin(
        modules: [
          _module('live', incidents: 2),
          _module('wallet', incidents: 1),
          _module('brain', incidents: 0),
        ],
        lastUpdated: DateTime.now(),
      );
      expect(twin.totalIncidents, 3);
    });

    test('ecosystemStatus is critical when any module is critical', () {
      final twin = YohPalDigitalTwin(
        modules: [
          _module('live'),
          _module('wallet', status: HealthStatus.critical),
        ],
        lastUpdated: DateTime.now(),
      );
      expect(twin.ecosystemStatus, HealthStatus.critical);
    });

    test('ecosystemStatus is warning when no critical but some warning', () {
      final twin = YohPalDigitalTwin(
        modules: [
          _module('live'),
          _module('hustle', status: HealthStatus.warning),
        ],
        lastUpdated: DateTime.now(),
      );
      expect(twin.ecosystemStatus, HealthStatus.warning);
    });

    test('ecosystemStatus is healthy when all modules healthy', () {
      final twin = YohPalDigitalTwin(
        modules: [_module('live'), _module('hustle'), _module('jobs')],
        lastUpdated: DateTime.now(),
      );
      expect(twin.ecosystemStatus, HealthStatus.healthy);
    });

    test('criticalModules filters correctly', () {
      final twin = YohPalDigitalTwin(
        modules: [
          _module('live', status: HealthStatus.critical),
          _module('hustle'),
          _module('wallet', status: HealthStatus.critical),
        ],
        lastUpdated: DateTime.now(),
      );
      expect(twin.criticalModules.map((m) => m.module), ['live', 'wallet']);
    });

    test('moduleHealth returns correct module', () {
      final twin = YohPalDigitalTwin(
        modules: [_module('live', activeUsers: 9999)],
        lastUpdated: DateTime.now(),
      );
      expect(twin.moduleHealth('live')?.activeUsers, 9999);
    });

    test('moduleHealth returns null for unknown module', () {
      final twin = YohPalDigitalTwin(
        modules: [_module('live')],
        lastUpdated: DateTime.now(),
      );
      expect(twin.moduleHealth('unknown'), isNull);
    });
  });

  group('PredictiveRiskDetector', () {
    test('liveLatencyRising returns null below threshold', () {
      expect(PredictiveRiskDetector.liveLatencyRising(1500), isNull);
    });

    test('liveLatencyRising returns risk above threshold', () {
      final risk = PredictiveRiskDetector.liveLatencyRising(3000);
      expect(risk, isNotNull);
      expect(risk!.module, 'live');
      expect(risk.isHighProbability, true);
    });

    test('walletFailuresRising returns null below threshold', () {
      expect(PredictiveRiskDetector.walletFailuresRising(0.005), isNull);
    });

    test('walletFailuresRising returns risk above threshold', () {
      final risk = PredictiveRiskDetector.walletFailuresRising(0.08);
      expect(risk, isNotNull);
      expect(risk!.module, 'wallet');
      expect(risk.recommendation, contains('Pause payouts'));
    });

    test('ffmpegQueueBuilding returns null for small queue', () {
      expect(PredictiveRiskDetector.ffmpegQueueBuilding(5), isNull);
    });

    test('ffmpegQueueBuilding returns risk for large queue', () {
      final risk = PredictiveRiskDetector.ffmpegQueueBuilding(40);
      expect(risk, isNotNull);
      expect(risk!.recommendation, contains('Cloud Run'));
    });

    test('probability clamps to 1.0 maximum', () {
      final risk = PredictiveRiskDetector.liveLatencyRising(99999);
      expect(risk!.probability, lessThanOrEqualTo(1.0));
    });
  });
}
