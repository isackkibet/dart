import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/platform/os/events/yohpal_enterprise_event.dart';
import 'package:yohpal_live_v2/platform/os/automation/automation_policy.dart';
import 'package:yohpal_live_v2/platform/os/approvals/approval_request.dart';
import 'package:yohpal_live_v2/platform/os/digital_twin/yohpal_os_digital_twin.dart';

YohPalModuleState _state(
  String name, {
  String health = 'healthy',
  double availability = 99.9,
  double latencyMs = 100,
  int activeUsers = 1000,
  int openIncidents = 0,
}) =>
    YohPalModuleState(
      module: name,
      health: health,
      availability: availability,
      latencyMs: latencyMs,
      activeUsers: activeUsers,
      openIncidents: openIncidents,
    );

void main() {
  group('YohPalEnterpriseEvent', () {
    test('toMap serialises all fields', () {
      final now = DateTime(2026, 7, 9, 12, 0, 0);
      final event = YohPalEnterpriseEvent(
        id: 'evt-001',
        module: 'live',
        type: 'module.health.changed',
        severity: 'warning',
        payload: {'latencyMs': 3200},
        createdAt: now,
      );
      final map = event.toMap();
      expect(map['id'], 'evt-001');
      expect(map['module'], 'live');
      expect(map['type'], 'module.health.changed');
      expect(map['severity'], 'warning');
      expect((map['payload'] as Map)['latencyMs'], 3200);
      expect(map['createdAt'], now.toIso8601String());
    });

    test('toMap payload is a map', () {
      final event = YohPalEnterpriseEvent(
        id: 'e2',
        module: 'wallet',
        type: 'wallet.transaction.failed',
        severity: 'critical',
        payload: {'txId': 'abc'},
        createdAt: DateTime.now(),
      );
      expect(event.toMap()['payload'], isA<Map>());
    });
  });

  group('AutomationPolicy', () {
    test('defaults: requiresApproval true, role admin, enabled true', () {
      const p = AutomationPolicy(
        id: 'p1',
        name: 'Pause on crash',
        triggerType: 'crash.rate.exceeded',
        actionType: 'pause.rollout',
      );
      expect(p.requiresApproval, true);
      expect(p.minimumApproverRole, 'admin');
      expect(p.enabled, true);
    });

    test('can override defaults', () {
      const p = AutomationPolicy(
        id: 'p2',
        name: 'Scale AI workers',
        triggerType: 'ai.latency.warning',
        actionType: 'scale.service',
        requiresApproval: false,
        minimumApproverRole: 'ops',
        enabled: false,
      );
      expect(p.requiresApproval, false);
      expect(p.minimumApproverRole, 'ops');
      expect(p.enabled, false);
    });
  });

  group('ApprovalRequest', () {
    test('stores all required fields', () {
      final now = DateTime(2026, 7, 9);
      final req = ApprovalRequest(
        id: 'req-1',
        action: 'rollback',
        module: 'live',
        status: 'pending',
        requestedBy: 'engineer@yohpal.com',
        createdAt: now,
      );
      expect(req.id, 'req-1');
      expect(req.action, 'rollback');
      expect(req.status, 'pending');
      expect(req.approvedBy, isNull);
    });

    test('approvedBy is set when provided', () {
      final req = ApprovalRequest(
        id: 'req-2',
        action: 'wallet.freeze',
        module: 'wallet',
        status: 'approved',
        requestedBy: 'alice@yohpal.com',
        approvedBy: 'cto@yohpal.com',
        createdAt: DateTime.now(),
      );
      expect(req.approvedBy, 'cto@yohpal.com');
    });
  });

  group('YohPalOSDigitalTwin', () {
    test('ecosystemAvailability is mean of all modules', () {
      final twin = YohPalOSDigitalTwin(
        modules: [
          _state('live', availability: 99.9),
          _state('hustle', availability: 99.5),
          _state('wallet', availability: 100.0),
        ],
        updatedAt: DateTime.now(),
      );
      expect(twin.ecosystemAvailability, closeTo(99.8, 0.01));
    });

    test('ecosystemAvailability is 0 for empty list', () {
      final twin =
          YohPalOSDigitalTwin(modules: [], updatedAt: DateTime.now());
      expect(twin.ecosystemAvailability, 0);
    });

    test('hasCriticalIncident is true when any module is critical', () {
      final twin = YohPalOSDigitalTwin(
        modules: [
          _state('live'),
          _state('wallet', health: 'critical'),
        ],
        updatedAt: DateTime.now(),
      );
      expect(twin.hasCriticalIncident, true);
    });

    test('hasCriticalIncident is false when all modules healthy', () {
      final twin = YohPalOSDigitalTwin(
        modules: [_state('live'), _state('brain'), _state('jobs')],
        updatedAt: DateTime.now(),
      );
      expect(twin.hasCriticalIncident, false);
    });

    test('hasCriticalIncident is false for warning modules', () {
      final twin = YohPalOSDigitalTwin(
        modules: [_state('live', health: 'warning')],
        updatedAt: DateTime.now(),
      );
      expect(twin.hasCriticalIncident, false);
    });
  });
}
