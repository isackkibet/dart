import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../contracts/streaming_controller_contracts.dart';
import '../config/yohpal_streaming_config.dart';
import '../models/yohpal_transport_info.dart';
import '../rtc/yohpal_peer_factory.dart';
import '../rtc/yohpal_dtls_helper.dart';
import '../rtc/yohpal_rtp_parameter_builder.dart';
import '../signaling/yohpal_signal_message.dart';
import '../signaling/yohpal_signaling_client.dart';
import '../signaling/web_socket_signaling_transport.dart';

final class YohPalBroadcasterController implements YohPalBroadcasterContract {
  final YohPalStreamingConfig config;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  final StreamController<int> _viewerCountController =
      StreamController<int>.broadcast();
  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();

  YohPalSignalingClient? _signaling;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  StreamSubscription<YohPalSignalMessage>? _eventsSub;

  bool _previewInitialized = false;
  bool _isLive = false;

  bool get previewInitialized => _previewInitialized;
  bool get isLive => _isLive;

  YohPalBroadcasterController({
    required this.config,
  });

  @override
  Stream<int> get viewerCountStream => _viewerCountController.stream;

  @override
  Stream<void> get disconnectedStream => _disconnectController.stream;

  Future<void> initializePreview() async {
    if (_previewInitialized) return;

    await localRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    });

    localRenderer.srcObject = _localStream;
    _previewInitialized = true;
  }

  @override
  Future<void> startBroadcast({
    required String roomId,
    required String accessToken,
  }) async {
    if (!_previewInitialized) {
      throw StateError('Preview must be initialized before going live');
    }

    final transport = WebSocketSignalingTransport(
      Uri.parse(config.wsUrl),
    );
    transport.connect();

    _signaling = YohPalSignalingClient(transport: transport);
    _signaling!.connect();

    _eventsSub = _signaling!.events.listen((event) {
      if (event.action == 'viewerCount') {
        final count = event.data['count'] as int? ?? 0;
        _viewerCountController.add(count);
      } else if (event.action == 'socketClosed') {
        _disconnectController.add(null);
      }
    });

    final join = await _signaling!.request('joinRoom', {
      'roomId': roomId,
      'role': 'broadcaster',
      'token': accessToken,
    });

    if (join.data['rtpCapabilities'] == null) {
      throw StateError('Missing router RTP capabilities');
    }

    _peerConnection = await YohPalPeerFactory.buildPeerConnection();

    for (final track
        in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    final transportCreated = await _signaling!.request('createTransport', {
      'direction': 'send',
    });

    final transportInfo = YohPalTransportInfo.fromSignal(transportCreated.data);

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    final clientDtlsParameters =
        YohPalDtlsHelper.extractDtlsParametersFromSdp(offer.sdp ?? '');

    await _signaling!.request('connectTransport', {
      'transportId': transportInfo.id,
      'dtlsParameters': clientDtlsParameters,
    });

    final senders = await _peerConnection!.getSenders();
    for (final sender in senders) {
      final track = sender.track;
      if (track == null) continue;

      await _signaling!.request('produce', {
        'transportId': transportInfo.id,
        'kind': track.kind,
        'rtpParameters': YohPalRtpParameterBuilder.buildForTrack(track),
      });
    }

    _isLive = true;
  }

  @override
  Future<void> stopBroadcast() async {
    try {
      await _signaling?.request('leaveRoom', {});
    } catch (_) {}

    await _eventsSub?.cancel();
    await _peerConnection?.close();

    for (final track
        in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }

    await _localStream?.dispose();

    await _signaling?.close();

    _isLive = false;
  }

  @override
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  }) async {
    await stopBroadcast();
    await startBroadcast(
      roomId: roomId,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> dispose() async {
    await stopBroadcast();
    if (_previewInitialized) {
      await localRenderer.dispose();
      _previewInitialized = false;
    }
    await _viewerCountController.close();
    await _disconnectController.close();
  }
}
