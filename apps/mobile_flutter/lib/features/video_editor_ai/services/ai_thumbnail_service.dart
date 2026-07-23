import '../repositories/ai_video_repository.dart';
import 'ai_creator_api_service.dart';

class AiThumbnailService {
  final AiVideoRepository repository;
  final AiCreatorApiService api;

  AiThumbnailService({required this.repository, required this.api});

  Future<String> generateThumbnailIdeas({
    required String userId,
    required String videoId,
    required String topic,
  }) async {
    final jobId = await repository.createJob(
      userId: userId,
      videoId: videoId,
      type: 'thumbnail_ideas',
      input: {'topic': topic},
    );
    await api.requestJobProcessing(jobId: jobId, userId: userId);
    return jobId;
  }
}
