/// Canonical video record for the Zero-Wait 100-video buffer system.
///
/// URL cascade for [resolvePlaybackUrl]:
///   preview-only  → previewUrl → hlsLowUrl → videoUrl
///   prefer HD     → hlsHdUrl → hlsStandardUrl → hlsMasterUrl → videoUrl
///   default       → previewUrl → hlsLowUrl → hlsStandardUrl → videoUrl
final class PreloadVideo {
  const PreloadVideo({
    required this.id,
    required this.feedIndex,
    required this.thumbnailUrl,
    required this.videoUrl,
    this.previewUrl,
    this.hlsLowUrl,
    this.hlsStandardUrl,
    this.hlsHdUrl,
    this.hlsMasterUrl,
    this.createdAt,
  });

  final String id;
  final int feedIndex;
  final String thumbnailUrl;
  final String videoUrl;
  final String? previewUrl;
  final String? hlsLowUrl;
  final String? hlsStandardUrl;
  final String? hlsHdUrl;
  final String? hlsMasterUrl;
  final DateTime? createdAt;

  String resolvePlaybackUrl({bool preferHd = false, bool previewOnly = false}) {
    if (previewOnly) {
      return _firstAvailable([previewUrl, hlsLowUrl]) ?? videoUrl;
    }
    if (preferHd) {
      return _firstAvailable([hlsHdUrl, hlsStandardUrl, hlsMasterUrl]) ?? videoUrl;
    }
    return _firstAvailable([previewUrl, hlsLowUrl, hlsStandardUrl]) ?? videoUrl;
  }

  PreloadVideo copyWith({int? feedIndex, String? thumbnailUrl}) => PreloadVideo(
        id: id,
        feedIndex: feedIndex ?? this.feedIndex,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        videoUrl: videoUrl,
        previewUrl: previewUrl,
        hlsLowUrl: hlsLowUrl,
        hlsStandardUrl: hlsStandardUrl,
        hlsHdUrl: hlsHdUrl,
        hlsMasterUrl: hlsMasterUrl,
        createdAt: createdAt,
      );

  factory PreloadVideo.fromJson(Map<String, dynamic> json) => PreloadVideo(
        id: (json['id'] as String?) ?? '',
        feedIndex: (json['feedIndex'] as int?) ?? 0,
        thumbnailUrl: (json['thumbnailUrl'] as String?) ?? '',
        videoUrl: (json['videoUrl'] as String?) ?? '',
        previewUrl: json['previewUrl'] as String?,
        hlsLowUrl: json['hlsLowUrl'] as String?,
        hlsStandardUrl: json['hlsStandardUrl'] as String?,
        hlsHdUrl: json['hlsHdUrl'] as String?,
        hlsMasterUrl: json['hlsMasterUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'feedIndex': feedIndex,
        'thumbnailUrl': thumbnailUrl,
        'videoUrl': videoUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        if (hlsLowUrl != null) 'hlsLowUrl': hlsLowUrl,
        if (hlsStandardUrl != null) 'hlsStandardUrl': hlsStandardUrl,
        if (hlsHdUrl != null) 'hlsHdUrl': hlsHdUrl,
        if (hlsMasterUrl != null) 'hlsMasterUrl': hlsMasterUrl,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  factory PreloadVideo.fromFirestore(Map<String, dynamic> data) => PreloadVideo(
        id: (data['id'] as String?) ?? '',
        feedIndex: (data['feedIndex'] as int?) ?? 0,
        thumbnailUrl: (data['thumbnailUrl'] as String?) ?? '',
        videoUrl: (data['videoUrl'] as String?) ?? '',
        previewUrl: data['previewUrl'] as String?,
        hlsLowUrl: data['hlsLowUrl'] as String?,
        hlsStandardUrl: data['hlsStandardUrl'] as String?,
        hlsHdUrl: data['hlsHdUrl'] as String?,
        hlsMasterUrl: data['hlsMasterUrl'] as String?,
      );

  static String? _firstAvailable(List<String?> candidates) {
    for (final c in candidates) {
      if (c != null && c.isNotEmpty) return c;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is PreloadVideo && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PreloadVideo(id: $id, feedIndex: $feedIndex)';
}
