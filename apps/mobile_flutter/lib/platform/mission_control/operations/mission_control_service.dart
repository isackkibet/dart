import '../digital_twin/yohpal_digital_twin.dart';
import '../predictive/predictive_risk.dart';

abstract class MissionControlService {
  Stream<YohPalDigitalTwin> watchEcosystem();

  Future<List<PredictiveRisk>> getPredictiveRisks();

  Future<void> acknowledgeIncident(String incidentId);

  Future<void> triggerRollback(String release);

  Future<void> pauseRollout(String module);

  Future<void> resumeRollout(String module);
}
