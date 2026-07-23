abstract class YohPalAnalyticsService {
  Future<void> track({
    required String event,
    required String module,
    Map<String, dynamic>? properties,
  });
  Future<void> screenView({
    required String screen,
    required String module,
  });
}
