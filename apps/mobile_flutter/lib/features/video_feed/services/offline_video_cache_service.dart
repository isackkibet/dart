import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class OfflineVideoCacheService {
  final BaseCacheManager cacheManager;

  OfflineVideoCacheService({BaseCacheManager? cacheManager})
      : cacheManager = cacheManager ?? DefaultCacheManager();

  Future<void> cacheVideoUrl(String url) async {
    if (url.isEmpty) return;
    await cacheManager.downloadFile(url);
  }

  Future<bool> isCached(String url) async {
    if (url.isEmpty) return false;
    final file = await cacheManager.getFileFromCache(url);
    return file != null;
  }

  Future<void> clear() async {
    await cacheManager.emptyCache();
  }
}
