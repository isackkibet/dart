import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;

class YohPalPeerFactory {
  static Future<rtc.RTCPeerConnection> buildPeerConnection({
    Map<String, dynamic>? configuration,
  }) {
    return rtc.createPeerConnection(
      configuration ??
          {
            'iceServers': [
              {'urls': 'stun:stun.l.google.com:19302'},
            ],
            'sdpSemantics': 'unified-plan',
          },
    );
  }
}
