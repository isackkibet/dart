import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for preview MP4s and low-bitrate playback URL segments.
///
/// HLS (.m3u8) manifests are NOT reliably cacheable through this layer —
/// use platform-native caching (ExoPlayer SimpleCache / AVAsset) for full
/// HLS offline. This cache is for direct MP4 previews and initial segments only.
final class VideoMediaCache {
  VideoMediaCache({CacheManager? cacheManager})
      : _cache = cacheManager ??
            CacheManager(
              Config(
                'yohpal_zero_wait_media_v2',
                stalePeriod: const Duration(days: 3),
                maxNrOfCacheObjects: 350,
                repo: JsonCacheInfoRepository(
                  databaseName: 'yohpal_zero_wait_media_v2',
                ),
                fileService: HttpFileService(),
              ),
            );

  final BaseCacheManager _cache;

  /// Returns the cached file if already on disk; does not download.
  Future<File?> getCached(String url) async {
    if (url.isEmpty) return null;
    try {
      final info = await _cache.getFileFromCache(url);
      final file = info?.file;
      if (file != null && file.existsSync()) return file;
    } catch (_) {}
    return null;
  }

  /// Downloads [url] to disk in the background. Silent on failure.
  Future<void> prefetch(String url) async {
    if (url.isEmpty) return;
    try {
      await _cache.downloadFile(url);
    } catch (_) {
      // Warm failures must never surface to the UI.
    }
  }

  Future<void> evict(String url) async {
    try {
      await _cache.removeFile(url);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _cache.emptyCache();
    } catch (_) {}
  }
}
