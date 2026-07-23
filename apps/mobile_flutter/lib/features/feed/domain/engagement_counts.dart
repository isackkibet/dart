final class EngagementCounts {
  const EngagementCounts({
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saves,
    required this.gifts,
    required this.viewerHasLiked,
    required this.viewerHasSaved,
  });

  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final int gifts;
  final bool viewerHasLiked;
  final bool viewerHasSaved;

  factory EngagementCounts.empty() => const EngagementCounts(
        views: 0,
        likes: 0,
        comments: 0,
        shares: 0,
        saves: 0,
        gifts: 0,
        viewerHasLiked: false,
        viewerHasSaved: false,
      );

  factory EngagementCounts.fromMap(Map<String, dynamic> map, {bool viewerHasLiked = false, bool viewerHasSaved = false}) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    return EngagementCounts(
      views: parseInt(map['views'] ?? map['viewsCount']),
      likes: parseInt(map['likes'] ?? map['likesCount']),
      comments: parseInt(map['comments'] ?? map['commentsCount']),
      shares: parseInt(map['shares'] ?? map['sharesCount']),
      saves: parseInt(map['saves'] ?? map['savesCount']),
      gifts: parseInt(map['gifts'] ?? map['giftsCount']),
      viewerHasLiked: viewerHasLiked,
      viewerHasSaved: viewerHasSaved,
    );
  }

  EngagementCounts copyWith({
    int? views,
    int? likes,
    int? comments,
    int? shares,
    int? saves,
    int? gifts,
    bool? viewerHasLiked,
    bool? viewerHasSaved,
  }) =>
      EngagementCounts(
        views: views ?? this.views,
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        shares: shares ?? this.shares,
        saves: saves ?? this.saves,
        gifts: gifts ?? this.gifts,
        viewerHasLiked: viewerHasLiked ?? this.viewerHasLiked,
        viewerHasSaved: viewerHasSaved ?? this.viewerHasSaved,
      );
}
