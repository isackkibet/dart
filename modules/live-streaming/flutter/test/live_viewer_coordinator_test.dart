import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:yohpal_live_streaming/src/contracts/streaming_controller_contracts.dart';
import 'package:yohpal_live_streaming/src/integration/live_viewer_coordinator.dart';
import 'package:yohpal_live_streaming/src/models/yohpal_streaming_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('FlutterWebRTC.Method'),
      (MethodCall methodCall) async => <String, dynamic>{
        'textureId': 0,
      },
    );
  });

  test('join transitions viewer to live', () async {
    final fake = FakeViewerController();
    final coordinator = LiveViewerCoordinator(controller: fake);
    await coordinator.initialize();
    await coordinator.join(
      roomId: 'room-1',
      accessToken: 'token',
    );
    expect(fake.joined, isTrue);
    expect(
      coordinator.state.phase,
      YohPalStreamingPhase.live,
    );
  });

  test(
    'stream ended event updates viewer state',
    () async {
      final fake = FakeViewerController();
      final coordinator = LiveViewerCoordinator(controller: fake);
      await coordinator.initialize();
      fake.ended.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(
        coordinator.state.phase,
        YohPalStreamingPhase.ended,
      );
    },
  );

  test('join timeout becomes failed state', () async {
    final fake = FakeViewerController(
      joinError: TimeoutException('timeout'),
    );
    final coordinator = LiveViewerCoordinator(controller: fake);
    await coordinator.initialize();
    await coordinator.join(
      roomId: 'room-1',
      accessToken: 'token',
    );
    expect(
      coordinator.state.phase,
      YohPalStreamingPhase.failed,
    );
  });
}

final class FakeViewerController implements YohPalViewerContract {
  FakeViewerController({
    this.joinError,
  });

  final Object? joinError;
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final disconnects = StreamController<void>.broadcast();
  final ended = StreamController<void>.broadcast();
  bool joined = false;

  @override
  RTCVideoRenderer get remoteRenderer => _renderer;

  @override
  Stream<void> get disconnectedStream => disconnects.stream;

  @override
  Stream<void> get streamEndedStream => ended.stream;

  @override
  Future<void> joinStream({
    required String roomId,
    required String accessToken,
  }) async {
    if (joinError != null) throw joinError!;
    joined = true;
  }

  @override
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  }) async {
    joined = true;
  }

  @override
  Future<void> leaveStream() async {
    joined = false;
  }

  @override
  Future<void> dispose() async {
    await disconnects.close();
    await ended.close();
    await _renderer.dispose();
  }
}
