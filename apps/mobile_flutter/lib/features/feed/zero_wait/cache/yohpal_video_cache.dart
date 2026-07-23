import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for preview MP4 segments used by the zero-wait warm tier.
///
/// HLS manifests (.m3u8) are NOT reliably cacheable here — this layer targets
/// direct MP4 preview URLs and low-bitrate start segments only.
final class YohPalVideoCache {
  YohPalVideoCache({BaseCacheManager? cacheManager})
      : _manager = cacheManager ??
            CacheManager(
              Config(
                'yohpal_zw_video_v1',
                stalePeriod: const Duration(days: 3),
                maxNrOfCacheObjects: 300,
                repo: JsonCacheInfoRepository(
                  databaseName: 'yohpal_zw_video_v1',
                ),
                fileService: HttpFileService(),
              ),
            );

  final BaseCacheManager _manager;

  /// Returns the cached [File] if it exists on disk; does NOT trigger a download.
  Future<File?> find(String url) async {
    if (url.isEmpty) return null;
    try {
      final info = await _manager.getFileFromCache(url);
      final file = info?.file;
      if (file != null && file.existsSync()) return file;
    } catch (_) {}
    return null;
  }

  /// Downloads [url] to the disk cache and returns the [File] on success.
  /// Returns `null` on failure — warm misses must never surface to the UI.
  Future<File?> download(String url) async {
    if (url.isEmpty) return null;
    try {
      final file = await _manager.downloadFile(url);
      return file.file;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String url) async {
    try {
      await _manager.removeFile(url);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _manager.emptyCache();
    } catch (_) {}
  }
}
