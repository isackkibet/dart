class YohPalFeedVideoSource {
  final String id;
  final String creatorId;
  final String low360Url;
  final String medium480Url;
  final String high720Url;
  final String? hlsMasterUrl;
  final String? hls360Url;
  final String? hls720Url;
  final bool hlsReady;
  final String recommendedDelivery;
  final String recommendedQuality;
  final int preloadPriority;
  final double videoWeight;
  final double predictedWatchProbability;
  final Map<String, String> headers;

  const YohPalFeedVideoSource({
    required this.id,
    required this.creatorId,
    required this.low360Url,
    required this.medium480Url,
    required this.high720Url,
    this.hlsMasterUrl,
    this.hls360Url,
    this.hls720Url,
    required this.hlsReady,
    required this.recommendedDelivery,
    required this.recommendedQuality,
    required this.preloadPriority,
    required this.videoWeight,
    required this.predictedWatchProbability,
    this.headers = const {},
  });

  factory YohPalFeedVideoSource.fromJson(Map<String, dynamic> json) {
    return YohPalFeedVideoSource(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
      low360Url: json['low360Url'] as String,
      medium480Url: json['medium480Url'] as String,
      high720Url: json['high720Url'] as String,
      hlsMasterUrl: json['hlsMasterUrl'] as String?,
      hls360Url: json['hls360Url'] as String?,
      hls720Url: json['hls720Url'] as String?,
      hlsReady: json['hlsReady'] as bool? ?? false,
      recommendedDelivery: json['recommendedDelivery'] as String? ?? 'mp4',
      recommendedQuality: json['recommendedQuality'] as String? ?? '480p',
      preloadPriority: json['preloadPriority'] as int? ?? 5,
      videoWeight: (json['videoWeight'] as num?)?.toDouble() ?? 0.0,
      predictedWatchProbability:
          (json['predictedWatchProbability'] as num?)?.toDouble() ?? 0.0,
      headers: Map<String, String>.from(
          (json['headers'] as Map?)?.cast<String, String>() ?? {}),
    );
  }

  String playbackUrl() {
    if (recommendedDelivery == 'hls' && hlsReady) {
      if (recommendedQuality == '720p' && hls720Url != null) return hls720Url!;
      if (recommendedQuality == '360p' && hls360Url != null) return hls360Url!;
      if (hlsMasterUrl != null) return hlsMasterUrl!;
    }
    if (recommendedQuality == '360p') return low360Url;
    if (recommendedQuality == '720p') return high720Url;
    return medium480Url;
  }
}
