import '../repositories/ai_video_repository.dart';
import 'ai_creator_api_service.dart';

class AiHashtagService {
  final AiVideoRepository repository;
  final AiCreatorApiService api;

  AiHashtagService({required this.repository, required this.api});

  Future<String> generateHashtags({
    required String userId,
    required String videoId,
    required String caption,
  }) async {
    final jobId = await repository.createJob(
      userId: userId,
      videoId: videoId,
      type: 'hashtags',
      input: {'caption': caption},
    );
    await api.requestJobProcessing(jobId: jobId, userId: userId);
    return jobId;
  }
}
