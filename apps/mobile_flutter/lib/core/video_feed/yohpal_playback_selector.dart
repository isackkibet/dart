import 'yohpal_feed_video_source.dart';

class YohPalPlaybackSelector {
  String resolveUrl(YohPalFeedVideoSource source) {
    return source.playbackUrl();
  }

  bool shouldUseHls(YohPalFeedVideoSource source) {
    return source.recommendedDelivery == 'hls' &&
        source.hlsReady &&
        source.hlsMasterUrl != null;
  }
}
