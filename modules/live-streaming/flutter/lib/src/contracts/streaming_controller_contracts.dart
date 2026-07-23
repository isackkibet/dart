import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract interface class YohPalBroadcasterContract {
  RTCVideoRenderer get localRenderer;
  Stream<int> get viewerCountStream;
  Stream<void> get disconnectedStream;
  Future<void> startBroadcast({
    required String roomId,
    required String accessToken,
  });
  Future<void> stopBroadcast();
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  });
  Future<void> dispose();
}

abstract interface class YohPalViewerContract {
  RTCVideoRenderer get remoteRenderer;
  Stream<void> get disconnectedStream;
  Stream<void> get streamEndedStream;
  Future<void> joinStream({
    required String roomId,
    required String accessToken,
  });
  Future<void> leaveStream();
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  });
  Future<void> dispose();
}
