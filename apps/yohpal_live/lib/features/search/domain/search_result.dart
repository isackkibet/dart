sealed class SearchResult {
  const SearchResult();
}

class VideoSearchResult extends SearchResult {
  const VideoSearchResult({
    required this.videoId,
    required this.title,
    required this.creatorName,
    required this.thumbnailUrl,
    required this.viewCount,
    required this.duration,
  });

  final String videoId;
  final String title;
  final String creatorName;
  final String thumbnailUrl;
  final int viewCount;
  final Duration duration;

  factory VideoSearchResult.fromMap(Map<String, dynamic> map) {
    final videoId = map['videoId']?.toString() ?? map['id']?.toString() ?? '';
    final title = map['title']?.toString() ?? '';
    final creatorName = map['creatorName']?.toString() ?? '';
    final thumbnailUrl = map['thumbnailUrl']?.toString() ?? '';
    final viewCount = (map['viewCount'] as num?)?.toInt() ?? 0;
    final durationSeconds = (map['durationSeconds'] as num?)?.toInt() ?? 0;

    return VideoSearchResult(
      videoId: videoId,
      title: title,
      creatorName: creatorName,
      thumbnailUrl: thumbnailUrl,
      viewCount: viewCount,
      duration: Duration(seconds: durationSeconds),
    );
  }
}

class CreatorSearchResult extends SearchResult {
  const CreatorSearchResult({
    required this.creatorId,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    required this.followerCount,
    required this.isVerified,
  });

  final String creatorId;
  final String displayName;
  final String username;
  final String avatarUrl;
  final int followerCount;
  final bool isVerified;

  factory CreatorSearchResult.fromMap(Map<String, dynamic> map) {
    final creatorId = map['creatorId']?.toString() ?? map['id']?.toString() ?? '';
    final displayName = map['displayName']?.toString() ?? '';
    final username = map['username']?.toString() ?? '';
    final avatarUrl = map['avatarUrl']?.toString() ?? '';
    final followerCount = (map['followerCount'] as num?)?.toInt() ?? 0;
    final isVerified = map['isVerified'] == true;

    return CreatorSearchResult(
      creatorId: creatorId,
      displayName: displayName,
      username: username,
      avatarUrl: avatarUrl,
      followerCount: followerCount,
      isVerified: isVerified,
    );
  }
}
