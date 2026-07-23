import 'package:connectivity_plus/connectivity_plus.dart';

import '../video_feed/yohpal_feed_video_source.dart';

/// Translates connectivity_plus ConnectivityResult to the API network-type
/// string accepted by the backend /video-feed?networkType= query param.
class YohPalNetworkAwareDeliveryService {
  final Connectivity _connectivity;

  YohPalNetworkAwareDeliveryService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Returns the current network type as a backend-compatible string.
  Future<String> currentNetworkType() async {
    final results = await _connectivity.checkConnectivity();
    return _toApiString(results);
  }

  /// Stream of network-type strings — use to reactively update delivery params.
  Stream<String> watchNetworkType() {
    return _connectivity.onConnectivityChanged.map(_toApiString);
  }

  /// Client-side quality override: returns the best playback URL from [source]
  /// after re-evaluating quality against the real current network, overriding
  /// the server recommendation when conditions are worse than expected.
  Future<String> resolvePlaybackUrl(YohPalFeedVideoSource source) async {
    final networkType = await currentNetworkType();
    return resolvePlaybackUrlForNetwork(source, networkType);
  }

  /// Pure, synchronous variant — use when networkType is already known.
  static String resolvePlaybackUrlForNetwork(
    YohPalFeedVideoSource source,
    String networkType,
  ) {
    final slowNetwork = networkType == '3g' || networkType == '2g';

    if (source.hlsReady) {
      if (slowNetwork) {
        if (source.hls360Url != null) return source.hls360Url!;
        if (source.hlsMasterUrl != null) return source.hlsMasterUrl!;
      } else {
        if (source.hls720Url != null) return source.hls720Url!;
        if (source.hlsMasterUrl != null) return source.hlsMasterUrl!;
      }
    }

    if (slowNetwork) return source.low360Url;
    if (networkType == 'wifi' || networkType == '5g') return source.high720Url;
    return source.medium480Url;
  }

  static String _toApiString(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return 'wifi';
    if (results.contains(ConnectivityResult.mobile)) return '4g';
    if (results.contains(ConnectivityResult.none)) return 'none';
    return '4g';
  }
}
