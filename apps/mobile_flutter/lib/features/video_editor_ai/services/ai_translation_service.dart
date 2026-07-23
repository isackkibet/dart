import '../repositories/ai_video_repository.dart';
import 'ai_creator_api_service.dart';

class AiTranslationService {
  final AiVideoRepository repository;
  final AiCreatorApiService api;

  AiTranslationService({required this.repository, required this.api});

  Future<String> translateCaptions({
    required String userId,
    required String videoId,
    required String targetLanguage,
  }) async {
    final jobId = await repository.createJob(
      userId: userId,
      videoId: videoId,
      type: 'translation',
      input: {'targetLanguage': targetLanguage},
    );
    await api.requestJobProcessing(jobId: jobId, userId: userId);
    return jobId;
  }
}
