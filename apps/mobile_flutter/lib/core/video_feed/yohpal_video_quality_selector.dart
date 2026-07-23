import 'yohpal_feed_video_source.dart';

class YohPalVideoQualitySelector {
  String selectUrl({
    required YohPalFeedVideoSource source,
    required bool isWifi,
    required bool lowDataMode,
    required bool hlsEnabled,
  }) {
    if (hlsEnabled && source.hlsMasterUrl != null) return source.hlsMasterUrl!;
    if (lowDataMode) return source.low360Url;
    if (isWifi) return source.high720Url;
    return source.medium480Url;
  }
}
