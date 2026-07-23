import 'creator_profile_video.dart';

final class CreatorProfilePageResult {
  const CreatorProfilePageResult({
    required this.videos,
    required this.hasMore,
    this.nextCursor,
  });

  final List<CreatorProfileVideo> videos;
  final bool hasMore;
  final String? nextCursor;
}
