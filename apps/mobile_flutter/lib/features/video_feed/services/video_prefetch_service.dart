import '../models/video_model.dart';
import 'offline_video_cache_service.dart';

class VideoPrefetchService {
  final OfflineVideoCacheService cacheService;

  VideoPrefetchService({required this.cacheService});

  Future<void> prefetchNextVideos({
    required List<VideoModel> videos,
    required int currentIndex,
    int count = 2,
  }) async {
    final next = videos.skip(currentIndex + 1).take(count);
    for (final video in next) {
      await cacheService.cacheVideoUrl(video.hlsUrl);
    }
  }
}
