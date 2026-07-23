import '../repositories/ai_video_repository.dart';
import 'ai_creator_api_service.dart';

class AiTrimService {
  final AiVideoRepository repository;
  final AiCreatorApiService api;

  AiTrimService({required this.repository, required this.api});

  Future<String> generateTrimSuggestions({
    required String userId,
    required String videoId,
    required String description,
  }) async {
    final jobId = await repository.createJob(
      userId: userId,
      videoId: videoId,
      type: 'trim_suggestions',
      input: {'description': description},
    );
    await api.requestJobProcessing(jobId: jobId, userId: userId);
    return jobId;
  }
}
