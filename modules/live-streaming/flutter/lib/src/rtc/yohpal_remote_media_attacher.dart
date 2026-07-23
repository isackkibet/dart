import 'package:flutter_webrtc/flutter_webrtc.dart';

class YohPalRemoteMediaAttacher {
  static Future<void> attachTrack({
    required RTCVideoRenderer renderer,
    required MediaStreamTrack track,
    required List<MediaStream> streams,
  }) async {
    if (streams.isNotEmpty) {
      renderer.srcObject = streams.first;
      return;
    }
    final stream = await createLocalMediaStream('remote-stream');
    await stream.addTrack(track);
    renderer.srcObject = stream;
  }
}
