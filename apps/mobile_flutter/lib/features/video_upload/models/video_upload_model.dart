class VideoUploadModel {
  final String videoId;
  final String userId;
  final String ownerUsername;
  final String title;
  final String caption;
  final List<String> hashtags;
  final String rawPath;
  final String status;
  final DateTime createdAt;

  const VideoUploadModel({
    required this.videoId,
    required this.userId,
    this.ownerUsername = '',
    required this.title,
    this.caption = '',
    this.hashtags = const [],
    required this.rawPath,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id':              videoId,
      'userId':          userId,
      'ownerId':         userId,
      'ownerUsername':   ownerUsername,
      'title':           title,
      // VideoModel reads 'caption' for overlay text, falling back to 'title'.
      'caption':         caption.isNotEmpty ? caption : title,
      'hashtags':        hashtags,
      'rawPath':         rawPath,
      'originalUrl':     rawPath,     // legacy field used by some query paths
      'status':          status,
      'processingStatus':'pending',   // finalizeVideoPlaybackAssets watches this
      'playbackReady':   false,
      'broken':          false,
      'visibility':      'public',
      'hlsUrl':          '',
      'videoUrl':        '',
      'thumbnailUrl':    '',
      'views':           0,
      'viewsCount':      0,
      'likes':           0,
      'likesCount':      0,
      'engagementScore': 0,
      // createdAt / updatedAt / timestamp overridden with serverTimestamp() in repository
    };
  }
}
