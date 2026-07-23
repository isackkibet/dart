import '../domain/feed_request.dart';
import '../domain/feed_video.dart';

abstract interface class FeedRepository {
  Future<FeedPageResult> loadFeed(FeedRequest request);
}

final class FeedPageResult {
  const FeedPageResult({
    required this.videos,
    required this.hasMore,
    this.nextCursor,
  });

  final List<FeedVideo> videos;
  final bool hasMore;
  final String? nextCursor;
}
