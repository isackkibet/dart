import '../context/floating_context.dart';
import 'floating_pilot_config.dart';

class FloatingPilotGate {
  final FloatingPilotConfig config;
  const FloatingPilotGate(this.config);
  bool canStart({
    required String uid,
    required FloatingContext context,
  }) {
    return config.isEligible(
      uid: uid,
      module: context.module,
    );
  }
}
