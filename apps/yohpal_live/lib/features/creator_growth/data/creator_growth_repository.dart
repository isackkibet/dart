import '../../../core/errors/app_failure.dart';
import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/creator_growth_score.dart';
import '../domain/growth_recommendation.dart';

class CreatorGrowthRepository {
  CreatorGrowthRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<CreatorGrowthScore>> getScore(String creatorId) async {
    final result = await _apiClient.getJson('/growth/creators/$creatorId/score');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Failure(
        AppFailure(
          message: 'Invalid creator growth score response.',
          code: 'invalid_growth_score_response',
        ),
      );
    }
    return Success(CreatorGrowthScore.fromMap(data));
  }

  Future<Result<List<GrowthRecommendation>>> getRecommendations(
    String creatorId,
  ) async {
    final result =
        await _apiClient.getJson('/growth/creators/$creatorId/recommendations');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) {
      return const Success([]);
    }
    final recommendations = data['recommendations'];
    if (recommendations is! List) {
      return const Success([]);
    }
    return Success(
      recommendations
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => GrowthRecommendation.fromMap(
              item['id']?.toString() ?? '',
              item,
            ),
          )
          .toList(),
    );
  }

  Future<Result<void>> generateRecommendations(String creatorId) async {
    final result = await _apiClient.postJson(
      '/growth/creators/$creatorId/recommendations/generate',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }
}
