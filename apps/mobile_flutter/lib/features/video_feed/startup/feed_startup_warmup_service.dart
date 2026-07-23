import '../../video_playback/controllers/zero_wait_playback_controller.dart';
import '../repositories/video_feed_repository.dart';

/// Result of a single warm-up pass: which video was gated on, and whether
/// its player controller actually finished initializing.
class FeedWarmupResult {
  final String? firstVideoId;
  final bool firstVideoReady;

  const FeedWarmupResult({
    required this.firstVideoId,
    required this.firstVideoReady,
  });
}

/// Pre-warms the first few suggested videos' player controllers during the
/// branded startup splash, so the feed's first video plays instantly instead
/// of showing a loading spinner.
///
/// Only the FIRST video is awaited — videos 2-4 are warmed in the background
/// without blocking startup, matching "do not open feed until: first video
/// controller is initialized OR fallback timeout expires" (the timeout
/// itself is enforced by the caller, e.g. YohPalBootstrap).
class FeedStartupWarmupService {
  final VideoFeedRepository feedRepository;
  final ZeroWaitPlaybackController zeroWaitController;

  FeedStartupWarmupService({
    required this.feedRepository,
    required this.zeroWaitController,
  });

  Future<FeedWarmupResult> warmupSuggestedFeed() async {
    final videos =
        await feedRepository.fetchInitialSuggestedVideos(limit: 4);
    if (videos.isEmpty) {
      return const FeedWarmupResult(firstVideoId: null, firstVideoReady: false);
    }

    final first = videos.first;
    final firstId = first['id']?.toString();

    await zeroWaitController.warmVideoAdaptive(first);

    // Fire-and-forget the rest — they continue warming after we return.
    for (final video in videos.skip(1)) {
      // ignore: unawaited_futures
      zeroWaitController.warmVideoAdaptive(video);
    }

    return FeedWarmupResult(
      firstVideoId: firstId,
      firstVideoReady:
          firstId != null && zeroWaitController.isPreloaded(firstId),
    );
  }
}
