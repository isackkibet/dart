import '../domain/feed_category.dart';
import '../domain/video_exposure.dart';

abstract interface class VideoExposureRepository {
  Future<void> recordExposure({
    required String videoId,
    required VideoExposureSource source,
    required double progress,
    required bool completed,
  });

  Future<Set<String>> loadAutomaticFeedExclusions({
    required FeedCategory category,
  });

  Future<void> synchronize();
}
