enum VideoExposureSource {
  recommended,
  following,
  search,
  creatorProfile,
  shared,
  saved,
  liked,
  history,
  ownVideo,
  swipeBack,
}

final class VideoExposure {
  const VideoExposure({
    required this.videoId,
    required this.firstShownAt,
    required this.lastShownAt,
    required this.maximumProgress,
    required this.source,
    required this.automaticFeedEligible,
    this.completedAt,
  });

  final String videoId;
  final DateTime firstShownAt;
  final DateTime lastShownAt;
  final double maximumProgress;
  final VideoExposureSource source;
  final bool automaticFeedEligible;
  final DateTime? completedAt;

  bool get substantiallyViewed =>
      completedAt != null || maximumProgress >= 0.80;
}
