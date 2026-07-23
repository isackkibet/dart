import 'package:flutter_webrtc/flutter_webrtc.dart';

class YohPalRtpParameterBuilder {
  static Map<String, dynamic> buildForTrack(MediaStreamTrack track) {
    final kind = track.kind;

    return {
      'mid': kind,
      'codecs': <Map<String, dynamic>>[
        if (kind == 'audio')
          {
            'mimeType': 'audio/opus',
            'clockRate': 48000,
            'channels': 2,
            'parameters': <String, dynamic>{},
            'rtcpFeedback': <Map<String, dynamic>>[],
            'payloadType': 111,
          },
        if (kind == 'video')
          {
            'mimeType': 'video/VP8',
            'clockRate': 90000,
            'parameters': <String, dynamic>{},
            'rtcpFeedback': <Map<String, dynamic>>[
              {'type': 'nack'},
              {'type': 'nack', 'parameter': 'pli'},
              {'type': 'goog-remb'},
            ],
            'payloadType': 96,
          },
      ],
      'headerExtensions': <Map<String, dynamic>>[],
      'encodings': <Map<String, dynamic>>[
        {
          'active': true,
        }
      ],
      'rtcp': <String, dynamic>{
        'cname': 'yohpal-${track.id}',
        'reducedSize': true,
        'mux': true,
      },
    };
  }
}
