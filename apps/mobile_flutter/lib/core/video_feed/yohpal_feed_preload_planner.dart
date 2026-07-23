import 'yohpal_feed_video_source.dart';

class YohPalFeedPreloadPlanner {
  List<YohPalFeedVideoSource> planPreload({
    required List<YohPalFeedVideoSource> videos,
    required int currentIndex,
  }) {
    final nearby = <YohPalFeedVideoSource>[];
    for (final index in [
      currentIndex + 1,
      currentIndex + 2,
      currentIndex - 1,
    ]) {
      if (index >= 0 && index < videos.length) {
        nearby.add(videos[index]);
      }
    }
    nearby.sort((a, b) {
      final priorityCompare = a.preloadPriority.compareTo(b.preloadPriority);
      if (priorityCompare != 0) return priorityCompare;
      return b.predictedWatchProbability.compareTo(a.predictedWatchProbability);
    });
    return nearby;
  }
}
