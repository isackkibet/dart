import 'pip_product_metrics.dart';

abstract class PipProductIntelligence {
  Future<void> recordSession(
    PipProductMetrics metrics,
  );
  Future<Map<String, dynamic>> generateDailyInsights();
}
