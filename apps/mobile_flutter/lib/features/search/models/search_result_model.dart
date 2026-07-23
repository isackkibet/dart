class SearchResultModel {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String imageUrl;
  final Map<String, dynamic> raw;

  const SearchResultModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.raw,
  });

  factory SearchResultModel.fromVideo(Map<String, dynamic> map) {
    return SearchResultModel(
      id: map['id'] ?? '',
      type: 'video',
      title: map['title'] ?? map['caption'] ?? 'Video',
      subtitle: map['creatorName'] ?? '',
      imageUrl: map['thumbnailUrl'] ?? '',
      raw: map,
    );
  }

  factory SearchResultModel.fromCreator(Map<String, dynamic> map) {
    return SearchResultModel(
      id: map['userId'] ?? map['id'] ?? '',
      type: 'creator',
      title: map['displayName'] ?? 'Creator',
      subtitle: map['bio'] ?? '',
      imageUrl: map['avatarUrl'] ?? map['photoUrl'] ?? '',
      raw: map,
    );
  }

  factory SearchResultModel.fromLive(Map<String, dynamic> map) {
    return SearchResultModel(
      id: map['id'] ?? '',
      type: 'live',
      title: map['title'] ?? 'Live',
      subtitle: '${map['viewerCount'] ?? 0} watching',
      imageUrl: map['thumbnailUrl'] ?? '',
      raw: map,
    );
  }

  factory SearchResultModel.fromBusiness(Map<String, dynamic> map) {
    return SearchResultModel(
      id: map['id'] ?? '',
      type: 'business',
      title: map['businessName'] ?? map['name'] ?? 'Business',
      subtitle: map['category'] ?? '',
      imageUrl: map['logoUrl'] ?? '',
      raw: map,
    );
  }
}
