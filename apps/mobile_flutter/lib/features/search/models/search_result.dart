enum SearchResultType { video, creator, live, business }

class SearchResult {
  final String id;
  final SearchResultType type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final Map<String, dynamic> extra;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.extra = const {},
  });

  factory SearchResult.fromVideo(String docId, Map<String, dynamic> data) =>
      SearchResult(
        id: docId,
        type: SearchResultType.video,
        title: data['caption'] ?? '',
        subtitle: '${data['views'] ?? 0} views',
        imageUrl: data['thumbnailUrl'] ?? '',
        extra: {'ownerId': data['ownerId'] ?? ''},
      );

  factory SearchResult.fromCreator(
          String docId, Map<String, dynamic> data) =>
      SearchResult(
        id: data['userId']?.toString().isNotEmpty == true
            ? data['userId']
            : docId,
        type: SearchResultType.creator,
        title: data['displayName'] ?? '',
        subtitle: '${data['followerCount'] ?? 0} followers',
        imageUrl: data['photoUrl'] ?? '',
      );

  factory SearchResult.fromLive(String docId, Map<String, dynamic> data) =>
      SearchResult(
        id: docId,
        type: SearchResultType.live,
        title: data['title'] ?? '',
        subtitle: '${data['viewerCount'] ?? 0} watching',
        imageUrl: '',
        extra: {'creatorId': data['creatorId'] ?? ''},
      );
}
