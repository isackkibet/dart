import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'yohpal_video_source.dart';

class YohPalVideoCacheManager {
  static final CacheManager cache = CacheManager(
    Config(
      'yohpal_video_cache',
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 100,
    ),
  );

  Future<void> preload(YohPalVideoSource source, String url) async {
    try {
      await cache.downloadFile(
        url,
        key: source.id,
        authHeaders: source.headers,
      );
    } catch (_) {
      // Preloading must never break feed playback.
    }
  }

  Future<void> clearOldCache() async => cache.emptyCache();
}
