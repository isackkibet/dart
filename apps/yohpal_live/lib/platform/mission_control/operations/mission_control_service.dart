import '../digital_twin/yohpal_digital_twin.dart';

abstract class MissionControlService {
  Stream<YohPalDigitalTwin> watchEcosystem();
  Future<void> acknowledgeIncident(String id);
  Future<void> triggerRollback(String release);
  Future<void> pauseRollout(String module);
  Future<void> resumeRollout(String module);
}
