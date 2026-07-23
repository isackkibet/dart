class ViewerVideoExposure {
  const ViewerVideoExposure({
    required this.viewerId,
    required this.videoId,
    required this.firstShownAt,
    required this.lastShownAt,
    required this.maximumProgressPercent,
    required this.source,
    required this.automaticFeedEligible,
    this.completedAt,
  });

  final String viewerId;
  final String videoId;
  final DateTime firstShownAt;
  final DateTime lastShownAt;
  final DateTime? completedAt;
  final double maximumProgressPercent;
  final String source;
  final bool automaticFeedEligible;

  Map<String, dynamic> toMap() => {
        'viewerId': viewerId,
        'videoId': videoId,
        'firstShownAt': firstShownAt.toIso8601String(),
        'lastShownAt': lastShownAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'maximumProgressPercent': maximumProgressPercent,
        'source': source,
        'automaticFeedEligible': automaticFeedEligible,
      };

  factory ViewerVideoExposure.fromMap(Map<String, dynamic> map) {
    return ViewerVideoExposure(
      viewerId: map['viewerId'] as String,
      videoId: map['videoId'] as String,
      firstShownAt: DateTime.parse(map['firstShownAt'] as String),
      lastShownAt: DateTime.parse(map['lastShownAt'] as String),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      maximumProgressPercent:
          (map['maximumProgressPercent'] as num).toDouble(),
      source: map['source'] as String,
      automaticFeedEligible: map['automaticFeedEligible'] as bool,
    );
  }
}

bool canAutomaticallyRecommendVideo({
  required String viewerId,
  required String creatorId,
  required String requestedSource,
  ViewerVideoExposure? exposure,
}) {
  if (viewerId == creatorId) return true;

  const intentionalSources = {
    'search',
    'profile',
    'shared',
    'saved',
    'liked',
    'history',
    'swipe_back',
  };

  if (intentionalSources.contains(requestedSource)) return true;
  if (exposure == null) return true;

  if (exposure.completedAt != null ||
      exposure.maximumProgressPercent >= 80) {
    return false;
  }

  return exposure.automaticFeedEligible;
}
