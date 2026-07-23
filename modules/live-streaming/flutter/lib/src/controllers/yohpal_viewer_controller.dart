import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../contracts/streaming_controller_contracts.dart';
import '../config/yohpal_streaming_config.dart';
import '../models/yohpal_consumer_info.dart';
import '../models/yohpal_producer_info.dart';
import '../models/yohpal_transport_info.dart';
import '../rtc/yohpal_peer_factory.dart';
import '../rtc/yohpal_dtls_helper.dart';
import '../rtc/yohpal_remote_media_attacher.dart';
import '../signaling/yohpal_signal_message.dart';
import '../signaling/yohpal_signaling_client.dart';
import '../signaling/web_socket_signaling_transport.dart';

final class YohPalViewerController implements YohPalViewerContract {
  final YohPalStreamingConfig config;
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  final StreamController<void> _disconnectController =
      StreamController<void>.broadcast();
  final StreamController<void> _streamEndedController =
      StreamController<void>.broadcast();

  YohPalSignalingClient? _signaling;
  RTCPeerConnection? _peerConnection;
  StreamSubscription<YohPalSignalMessage>? _eventsSub;

  String? _recvTransportId;
  Map<String, dynamic>? _routerRtpCapabilities;
  final Set<String> _consumedProducerIds = {};

  YohPalViewerController({
    required this.config,
  });

  Future<void> initialize() async {
    await remoteRenderer.initialize();
  }

  @override
  Stream<void> get disconnectedStream => _disconnectController.stream;

  @override
  Stream<void> get streamEndedStream => _streamEndedController.stream;

  @override
  Future<void> joinStream({
    required String roomId,
    required String accessToken,
  }) async {
    final wsTransport = WebSocketSignalingTransport(
      Uri.parse(config.wsUrl),
    );
    wsTransport.connect();

    _signaling = YohPalSignalingClient(transport: wsTransport);
    _signaling!.connect();

    _eventsSub = _signaling!.events.listen((event) async {
      if (event.action == 'newProducer') {
        final producer = YohPalProducerInfo.fromMap(event.data);
        await _consumeIfReady(producer);
      } else if (event.action == 'producerClosed') {
        // Producer closed; remote media will detach via track removal.
      } else if (event.action == 'socketClosed') {
        _disconnectController.add(null);
      } else if (event.action == 'streamEnded') {
        _streamEndedController.add(null);
      }
    });

    final join = await _signaling!.request('joinRoom', {
      'roomId': roomId,
      'role': 'viewer',
      'token': accessToken,
    });

    _routerRtpCapabilities =
        (join.data['rtpCapabilities'] as Map?)?.cast<String, dynamic>() ?? {};

    _peerConnection = await YohPalPeerFactory.buildPeerConnection();

    _peerConnection!.onTrack = (RTCTrackEvent event) async {
      if (event.track.kind == 'video') {
        await YohPalRemoteMediaAttacher.attachTrack(
          renderer: remoteRenderer,
          track: event.track,
          streams: event.streams,
        );
      }
    };

    final transportCreated = await _signaling!.request('createTransport', {
      'direction': 'recv',
    });

    final transport = YohPalTransportInfo.fromSignal(transportCreated.data);
    _recvTransportId = transport.id;

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    final clientDtlsParameters =
        YohPalDtlsHelper.extractDtlsParametersFromSdp(offer.sdp ?? '');

    await _signaling!.request('connectTransport', {
      'transportId': transport.id,
      'dtlsParameters': clientDtlsParameters,
    });

    final producerList = await _signaling!.request('listProducers', {});
    final producers = ((producerList.data['producers'] as List?) ?? const [])
        .map((e) =>
            YohPalProducerInfo.fromMap((e as Map).cast<String, dynamic>()))
        .toList();

    for (final producer in producers) {
      await _consumeIfReady(producer);
    }
  }

  Future<void> _consumeIfReady(YohPalProducerInfo producer) async {
    if (_recvTransportId == null || _routerRtpCapabilities == null) return;
    if (_consumedProducerIds.contains(producer.producerId)) return;

    final consumed = await _signaling!.request('consume', {
      'transportId': _recvTransportId,
      'producerId': producer.producerId,
      'rtpCapabilities': _routerRtpCapabilities,
    });

    final consumer = YohPalConsumerInfo.fromMap(consumed.data);

    await _signaling!.request('resumeConsumer', {
      'consumerId': consumer.consumerId,
    });

    _consumedProducerIds.add(producer.producerId);
  }

  @override
  Future<void> leaveStream() async {
    try {
      await _signaling?.request('leaveRoom', {});
    } catch (_) {}

    await _eventsSub?.cancel();
    await _peerConnection?.close();
    await _signaling?.close();
  }

  @override
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  }) async {
    await leaveStream();
    await joinStream(
      roomId: roomId,
      accessToken: accessToken,
    );
  }

  @override
  Future<void> dispose() async {
    await leaveStream();
    await remoteRenderer.dispose();
    await _disconnectController.close();
    await _streamEndedController.close();
  }
}
