import 'events/yohpal_event_bus.dart';
import 'automation/yohpal_automation_engine.dart';
import 'approvals/yohpal_approval_service.dart';
import 'digital_twin/yohpal_os_digital_twin.dart';

abstract class YohPalOS {
  YohPalEventBus get events;
  YohPalAutomationEngine get automation;
  YohPalApprovalService get approvals;
  Stream<YohPalOSDigitalTwin> watchDigitalTwin();
  Future<YohPalOSDigitalTwin> getCurrentState();
  Future<void> pauseModule(String module);
  Future<void> resumeModule(String module);
  Future<void> rollbackModule({
    required String module,
    required String releaseId,
  });
}
