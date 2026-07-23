import '../repositories/ai_video_repository.dart';
import 'ai_creator_api_service.dart';

class AiCaptionService {
  final AiVideoRepository repository;
  final AiCreatorApiService api;

  AiCaptionService({required this.repository, required this.api});

  Future<String> generateCaptions({
    required String userId,
    required String videoId,
    required String language,
  }) async {
    final jobId = await repository.createJob(
      userId: userId,
      videoId: videoId,
      type: 'captions',
      input: {'language': language},
    );
    await api.requestJobProcessing(jobId: jobId, userId: userId);
    return jobId;
  }
}
