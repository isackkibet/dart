import 'feed_category.dart';

final class FeedRequest {
  const FeedRequest({
    required this.category,
    required this.limit,
    required this.excludedVideoIds,
    this.cursor,
  });

  final FeedCategory category;
  final int limit;
  final Set<String> excludedVideoIds;
  final String? cursor;

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'limit': limit,
        'cursor': cursor,
        'excludedVideoIds': excludedVideoIds.toList(),
      };
}
