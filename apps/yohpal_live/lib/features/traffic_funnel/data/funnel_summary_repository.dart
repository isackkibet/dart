import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/funnel_summary.dart';

class FunnelSummaryRepository {
  FunnelSummaryRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<FunnelSummary>> getSessionSummary(String sessionId) async {
    final result = await _apiClient.getJson(
      '/traffic/sessions/$sessionId/funnel-summary',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Failure(
        AppFailure(
          message: 'Invalid funnel summary response.',
          code: 'invalid_funnel_summary_response',
        ),
      );
    }
    return Success(FunnelSummary.fromMap(data));
  }
}
