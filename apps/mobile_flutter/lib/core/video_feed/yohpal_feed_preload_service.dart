import 'yohpal_feed_cache_service.dart';
import 'yohpal_feed_video_source.dart';
import 'yohpal_video_quality_selector.dart';

class YohPalFeedPreloadService {
  final YohPalFeedCacheService cacheService;
  final YohPalVideoQualitySelector qualitySelector;

  YohPalFeedPreloadService({
    required this.cacheService,
    required this.qualitySelector,
  });

  Future<void> preloadAround({
    required List<YohPalFeedVideoSource> videos,
    required int currentIndex,
    required bool isWifi,
    required bool lowDataMode,
    required bool hlsEnabled,
  }) async {
    final targets = [currentIndex + 1, currentIndex + 2, currentIndex - 1];
    for (final index in targets) {
      if (index < 0 || index >= videos.length) continue;
      final video = videos[index];
      final url = qualitySelector.selectUrl(
        source: video,
        isWifi: isWifi,
        lowDataMode: lowDataMode,
        hlsEnabled: hlsEnabled,
      );
      await cacheService.preload(
        videoId: video.id,
        url: url,
        headers: video.headers,
      );
    }
  }
}
