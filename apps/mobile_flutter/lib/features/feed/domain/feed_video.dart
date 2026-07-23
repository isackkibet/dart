final class FeedVideo {
  const FeedVideo({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.caption,
    required this.videoUrl,
    required this.publishedAt,
    this.thumbnailUrl = '',
    this.creatorDisplayName = '',
    this.creatorUsername = '',
    this.creatorVerified = false,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.gifts = 0,
  });

  final String id;
  final String creatorId;
  final String creatorName;
  final String caption;
  final String videoUrl;
  final String thumbnailUrl;
  final String creatorDisplayName;
  final String creatorUsername;
  final bool creatorVerified;
  final DateTime publishedAt;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int gifts;

  factory FeedVideo.fromMap(Map<String, dynamic> map) {
    final username = map['ownerUsername'] as String? ??
        map['username'] as String? ??
        map['creatorName'] as String? ??
        '';
    final displayName = map['ownerDisplayName'] as String? ??
        map['displayName'] as String? ??
        username;
    return FeedVideo(
      id: map['id'] as String? ?? '',
      creatorId: map['creatorId'] as String? ?? map['ownerId'] as String? ?? '',
      creatorName: username,
      creatorDisplayName: displayName,
      creatorUsername: username,
      creatorVerified: map['ownerVerified'] as bool? ??
          map['isVerified'] as bool? ??
          false,
      caption: map['caption'] as String? ??
          map['description'] as String? ??
          '',
      videoUrl: map['videoUrl'] as String? ??
          map['hlsUrl'] as String? ??
          map['storageUrl'] as String? ??
          '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      publishedAt: _parseDate(map['createdAt'] ??
          map['publishedAt'] ??
          map['timestamp'] ??
          map['uploadedAt']),
      views: _int(map['views'] ?? map['viewsCount']),
      likes: _int(map['likes'] ?? map['likesCount']),
      comments: _int(map['comments'] ?? map['commentsCount']),
      shares: _int(map['shares'] ?? map['sharesCount']),
      saves: _int(map['saves'] ?? map['savesCount']),
      gifts: _int(map['gifts'] ?? map['giftsCount']),
    );
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  }

  static DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
