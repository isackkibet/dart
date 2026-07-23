import '../repositories/ai_video_repository.dart';
import 'ai_creator_api_service.dart';

class AiViralScoreService {
  final AiVideoRepository repository;
  final AiCreatorApiService api;

  AiViralScoreService({required this.repository, required this.api});

  Future<String> predictViralScore({
    required String userId,
    required String videoId,
    required String title,
    required String description,
  }) async {
    final jobId = await repository.createJob(
      userId: userId,
      videoId: videoId,
      type: 'viral_score',
      input: {'title': title, 'description': description},
    );
    await api.requestJobProcessing(jobId: jobId, userId: userId);
    return jobId;
  }
}
