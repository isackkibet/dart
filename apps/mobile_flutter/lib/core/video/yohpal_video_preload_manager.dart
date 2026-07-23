import 'yohpal_video_cache_manager.dart';
import 'yohpal_video_source.dart';

class YohPalVideoPreloadManager {
  final YohPalVideoCacheManager cacheManager;

  YohPalVideoPreloadManager(this.cacheManager);

  Future<void> preloadNext({
    required List<YohPalVideoSource> videos,
    required int currentIndex,
    required bool isWifi,
    required bool lowDataMode,
  }) async {
    final nextIndexes = [currentIndex + 1, currentIndex + 2];
    for (final index in nextIndexes) {
      if (index >= 0 && index < videos.length) {
        final video = videos[index];
        final url = video.bestUrl(
          isWifi: isWifi,
          lowDataMode: lowDataMode,
          hlsEnabled: false,
        );
        await cacheManager.preload(video, url);
      }
    }
  }
}
