class AdaptiveVideoUrlResolver {
  /// Best URL for first-frame speed: previewUrl → hlsLowUrl → hlsStandardUrl → hlsUrl → videoUrl
  String resolveStartUrl(Map<String, dynamic> video) {
    final previewUrl     = video['previewUrl']     as String?;
    final hlsLowUrl      = video['hlsLowUrl']      as String?;
    final hlsStandardUrl = video['hlsStandardUrl'] as String?;
    final hlsUrl         = video['hlsUrl']         as String?;
    final videoUrl       = video['videoUrl']       as String?;

    if (previewUrl     != null && previewUrl.isNotEmpty)     return previewUrl;
    if (hlsLowUrl      != null && hlsLowUrl.isNotEmpty)      return hlsLowUrl;
    if (hlsStandardUrl != null && hlsStandardUrl.isNotEmpty) return hlsStandardUrl;
    if (hlsUrl         != null && hlsUrl.isNotEmpty)         return hlsUrl;
    return videoUrl ?? '';
  }

  /// Best quality URL after first frame: hlsHdUrl → hlsStandardUrl → hlsUrl → videoUrl
  String resolveHdUrl(Map<String, dynamic> video) {
    final hlsHdUrl       = video['hlsHdUrl']       as String?;
    final hlsStandardUrl = video['hlsStandardUrl'] as String?;
    final hlsUrl         = video['hlsUrl']         as String?;
    final videoUrl       = video['videoUrl']       as String?;

    if (hlsHdUrl       != null && hlsHdUrl.isNotEmpty)       return hlsHdUrl;
    if (hlsStandardUrl != null && hlsStandardUrl.isNotEmpty) return hlsStandardUrl;
    if (hlsUrl         != null && hlsUrl.isNotEmpty)         return hlsUrl;
    return videoUrl ?? '';
  }

  /// Adaptive resolver: returns start URL on mobile, HD URL on wifi.
  String resolve({required Map<String, dynamic> videoData, required bool preferHd}) {
    return preferHd ? resolveHdUrl(videoData) : resolveStartUrl(videoData);
  }
}
