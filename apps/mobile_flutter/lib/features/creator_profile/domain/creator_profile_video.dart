import '../../video_feed/models/video_model.dart';

final class CreatorProfileVideo {
  const CreatorProfileVideo({
    required this.id,
    required this.thumbnailUrl,
    required this.views,
    required this.visibility,
    required this.publishedAt,
    required this.processingStatus,
  });

  final String id;
  final String thumbnailUrl;
  final int views;
  final String visibility;
  final DateTime publishedAt;
  final String processingStatus;

  factory CreatorProfileVideo.fromVideoModel(VideoModel model) {
    return CreatorProfileVideo(
      id: model.id,
      thumbnailUrl: model.thumbnailUrl,
      views: model.views,
      visibility: model.flagged ? 'flagged' : 'active',
      publishedAt: model.createdAt ?? DateTime.now(),
      processingStatus: model.moderationStatus.isNotEmpty
          ? model.moderationStatus
          : 'published',
    );
  }
}
