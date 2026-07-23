import '../context/floating_context.dart';
import '../runtime/floating_runtime.dart';
import 'floating_pilot_analytics.dart';
import 'floating_pilot_gate.dart';

class FloatingPilotRuntime implements FloatingRuntime {
  final FloatingRuntime innerRuntime;
  final FloatingPilotGate gate;
  final FloatingPilotAnalytics analytics;
  final String Function() currentUid;
  FloatingPilotRuntime({
    required this.innerRuntime,
    required this.gate,
    required this.analytics,
    required this.currentUid,
  });
  @override
  Future<bool> isSupported() {
    return innerRuntime.isSupported();
  }
  @override
  Future<bool> start(FloatingContext context) async {
    final uid = currentUid();
    if (!gate.canStart(uid: uid, context: context)) {
      await analytics.recordEvent(
        uid: uid,
        module: context.module,
        event: 'floating_pilot_blocked',
        properties: {'entityId': context.entityId},
      );
      return false;
    }
    final started = await innerRuntime.start(context);
    await analytics.recordEvent(
      uid: uid,
      module: context.module,
      event: started ? 'floating_pilot_started' : 'floating_pilot_failed',
      properties: {'entityId': context.entityId},
    );
    return started;
  }
  @override
  Future<void> stop() async {
    await innerRuntime.stop();
  }
  @override
  Future<void> restore() async {
    await innerRuntime.restore();
  }
}
