import '../../../core/models/result.dart';
import '../../../core/network/api_client.dart';
import '../domain/clip_segment.dart';
import '../domain/session_replay.dart';

class ClipFactoryRepository {
  ClipFactoryRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<SessionReplay?>> getSessionReplay(String sessionId) async {
    final result =
        await _apiClient.getJson('/clip-factory/sessions/$sessionId/replay');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    if (data is! Map<String, dynamic>) return const Success(null);
    final replay = data['replay'];
    if (replay is! Map<String, dynamic>) return const Success(null);
    return Success(
      SessionReplay.fromMap(replay['id']?.toString() ?? '', replay),
    );
  }

  Future<Result<List<ClipSegment>>> getClipSegments(String sessionId) async {
    final result =
        await _apiClient.getJson('/clip-factory/sessions/$sessionId/clips');
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    final data = result.dataOrNull?['data'];
    final items = data is Map<String, dynamic> ? data['clips'] : null;
    if (items is! List) return const Success([]);
    return Success(
      items
          .whereType<Map<String, dynamic>>()
          .map(
            (item) =>
                ClipSegment.fromMap(item['id']?.toString() ?? '', item),
          )
          .toList(),
    );
  }

  Future<Result<void>> generateClips(String sessionId) async {
    final result = await _apiClient.postJson(
      '/clip-factory/sessions/$sessionId/clips/generate',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  Future<Result<void>> updateClipStatus({
    required String sessionId,
    required String clipId,
    required String status,
  }) async {
    final result = await _apiClient.patchJson(
      '/clip-factory/sessions/$sessionId/clips/$clipId',
      body: {'status': status},
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }

  Future<Result<void>> distributeClip({
    required String sessionId,
    required String clipId,
  }) async {
    final result = await _apiClient.postJson(
      '/clip-factory/sessions/$sessionId/clips/$clipId/distribute',
    );
    if (result is Failure<Map<String, dynamic>>) {
      return Failure(result.failure);
    }
    return const Success(null);
  }
}
