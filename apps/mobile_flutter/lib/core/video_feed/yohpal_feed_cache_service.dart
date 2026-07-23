import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class YohPalFeedCacheService {
  final CacheManager cacheManager = CacheManager(
    Config(
      'yohpal_feed_video_cache',
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 150,
    ),
  );

  Future<void> preload({
    required String videoId,
    required String url,
    Map<String, String> headers = const {},
  }) async {
    try {
      await cacheManager.downloadFile(url, key: videoId, authHeaders: headers);
    } catch (_) {
      // Cache failure must never break playback.
    }
  }

  Future<String?> getCachedPath(String videoId) async {
    final file = await cacheManager.getFileFromCache(videoId);
    return file?.file.path;
  }

  Future<void> clear() async => cacheManager.emptyCache();
}
