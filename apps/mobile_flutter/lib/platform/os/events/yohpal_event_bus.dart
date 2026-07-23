import 'yohpal_enterprise_event.dart';

abstract class YohPalEventBus {
  Stream<YohPalEnterpriseEvent> watchEvents();

  Future<void> publish(YohPalEnterpriseEvent event);

  Future<List<YohPalEnterpriseEvent>> recent({
    String? module,
    String? severity,
    int limit = 100,
  });
}
