class VideoMetadata {
  final String title;
  final String caption;
  final List<String> hashtags;

  const VideoMetadata({
    required this.title,
    required this.caption,
    required this.hashtags,
  });

  const VideoMetadata.empty()
      : title = '',
        caption = '',
        hashtags = const [];

  VideoMetadata copyWith({
    String? title,
    String? caption,
    List<String>? hashtags,
  }) {
    return VideoMetadata(
      title: title ?? this.title,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
    );
  }
}
