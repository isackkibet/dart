class CreatorAggregateMetrics {
  const CreatorAggregateMetrics({
    required this.totalVideos,
    required this.totalViews,
    required this.totalLikes,
    required this.totalComments,
    required this.totalShares,
    required this.totalGifts,
    required this.followerCount,
  });

  final int totalVideos;
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final int totalGifts;
  final int followerCount;

  factory CreatorAggregateMetrics.fromJson(Map<String, dynamic> json) {
    return CreatorAggregateMetrics(
      totalVideos: json['totalVideos'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
      totalLikes: json['totalLikes'] as int? ?? 0,
      totalComments: json['totalComments'] as int? ?? 0,
      totalShares: json['totalShares'] as int? ?? 0,
      totalGifts: json['totalGifts'] as int? ?? 0,
      followerCount: json['followerCount'] as int? ?? 0,
    );
  }
}
