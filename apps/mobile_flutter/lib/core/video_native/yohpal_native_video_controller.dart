import 'package:flutter/services.dart';
import 'yohpal_native_video_source.dart';

class YohPalNativeVideoController {
  static const MethodChannel _channel = MethodChannel('yohpal.video/native');

  Future<void> load(YohPalNativeVideoSource source) {
    return _channel.invokeMethod('load', {
      'id': source.id,
      'url': source.url,
      'headers': source.headers,
    });
  }

  Future<void> loadUrl({
    required String id,
    required String url,
    Map<String, String> headers = const {},
  }) {
    return _channel.invokeMethod('load', {
      'id': id,
      'url': url,
      'headers': headers,
    });
  }

  Future<void> play() => _channel.invokeMethod('play');

  Future<void> pause() => _channel.invokeMethod('pause');

  Future<void> seekTo(int milliseconds) {
    return _channel.invokeMethod('seekTo', {'ms': milliseconds});
  }

  Future<void> setMuted(bool muted) {
    return _channel.invokeMethod('setMuted', {'muted': muted});
  }

  Future<void> dispose() => _channel.invokeMethod('dispose');
}
