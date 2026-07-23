import 'package:flutter/foundation.dart';
import '../models/ai_thumbnail_idea.dart';
import '../models/ai_video_job.dart';
import '../repositories/ai_publish_repository.dart';
import '../repositories/ai_video_repository.dart';
import '../services/ai_caption_service.dart';
import '../services/ai_hashtag_service.dart';
import '../services/ai_hook_service.dart';
import '../services/ai_thumbnail_service.dart';
import '../services/ai_trim_service.dart';
import '../services/ai_viral_score_service.dart';

class AiEditorController extends ChangeNotifier {
  final AiVideoRepository repository;
  final AiCaptionService captionService;
  final AiHookService hookService;
  final AiHashtagService hashtagService;
  final AiViralScoreService viralScoreService;
  final AiThumbnailService thumbnailService;
  final AiTrimService trimService;
  final AiPublishRepository publishRepository;

  bool loading = false;
  String? error;
  String? activeJobId;

  AiEditorController({
    required this.repository,
    required this.captionService,
    required this.hookService,
    required this.hashtagService,
    required this.viralScoreService,
    required this.thumbnailService,
    required this.trimService,
    required this.publishRepository,
  });

  Stream<AiVideoJob?> watchActiveJob() {
    final id = activeJobId;
    if (id == null) return const Stream.empty();
    return repository.watchJob(id);
  }

  Future<void> runCaptions({
    required String userId,
    required String videoId,
    required String language,
  }) async {
    await _run(() async {
      activeJobId = await captionService.generateCaptions(
        userId: userId,
        videoId: videoId,
        language: language,
      );
    });
  }

  Future<void> runHooks({
    required String userId,
    required String videoId,
    required String topic,
  }) async {
    await _run(() async {
      activeJobId = await hookService.generateHooks(
        userId: userId,
        videoId: videoId,
        topic: topic,
      );
    });
  }

  Future<void> runHashtags({
    required String userId,
    required String videoId,
    required String caption,
  }) async {
    await _run(() async {
      activeJobId = await hashtagService.generateHashtags(
        userId: userId,
        videoId: videoId,
        caption: caption,
      );
    });
  }

  Future<void> runViralScore({
    required String userId,
    required String videoId,
    required String title,
    required String description,
  }) async {
    await _run(() async {
      activeJobId = await viralScoreService.predictViralScore(
        userId: userId,
        videoId: videoId,
        title: title,
        description: description,
      );
    });
  }

  Future<void> runThumbnailIdeas({
    required String userId,
    required String videoId,
    required String topic,
  }) async {
    await _run(() async {
      activeJobId = await thumbnailService.generateThumbnailIdeas(
        userId: userId,
        videoId: videoId,
        topic: topic,
      );
    });
  }

  Future<void> runTrimSuggestions({
    required String userId,
    required String videoId,
    required String description,
  }) async {
    await _run(() async {
      activeJobId = await trimService.generateTrimSuggestions(
        userId: userId,
        videoId: videoId,
        description: description,
      );
    });
  }

  Future<void> applyCaptionToVideo({
    required String videoId,
    required String caption,
  }) async {
    await _run(() => publishRepository.applyCaption(
          videoId: videoId,
          caption: caption,
        ));
  }

  Future<void> applyHashtagsToVideo({
    required String videoId,
    required List<String> hashtags,
  }) async {
    await _run(() => publishRepository.applyHashtags(
          videoId: videoId,
          hashtags: hashtags,
        ));
  }

  Future<void> applyViralScoreToVideo({
    required String videoId,
    required int score,
    required String explanation,
  }) async {
    await _run(() => publishRepository.applyViralScore(
          videoId: videoId,
          score: score,
          explanation: explanation,
        ));
  }

  Future<void> applyThumbnailToVideo({
    required String videoId,
    required AiThumbnailIdea thumbnailIdea,
  }) async {
    await _run(() => publishRepository.applyThumbnailIdea(
          videoId: videoId,
          thumbnailIdea: thumbnailIdea.toMap(),
        ));
  }

  Future<void> markReadyForPublishing(String videoId) async {
    await _run(() => publishRepository.markAiReadyForPublishing(videoId));
  }

  Future<void> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
