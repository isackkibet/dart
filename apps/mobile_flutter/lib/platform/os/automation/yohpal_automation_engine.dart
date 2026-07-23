import '../events/yohpal_enterprise_event.dart';
import 'automation_policy.dart';

abstract class YohPalAutomationEngine {
  Future<void> evaluateEvent(YohPalEnterpriseEvent event);

  Future<void> registerPolicy(AutomationPolicy policy);

  Future<void> pauseRollout(String module);

  Future<void> triggerRollback(String module, String releaseId);

  Future<void> scaleService(String service, int targetInstances);
}
