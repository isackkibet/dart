import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:yohpal_live_streaming/src/contracts/streaming_controller_contracts.dart';
import 'package:yohpal_live_streaming/src/integration/go_live_coordinator.dart';
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

  test('start transitions broadcaster to live', () async {
    final fake = FakeBroadcasterController();
    final coordinator = GoLiveCoordinator(controller: fake);
    await coordinator.initialize();
    await coordinator.start(
      roomId: 'room-1',
      accessToken: 'token',
    );
    expect(fake.started, isTrue);
    expect(
      coordinator.state.phase,
      YohPalStreamingPhase.live,
    );
  });

  test(
    'timeout transitions broadcaster to failed',
    () async {
      final fake = FakeBroadcasterController(
        startError: TimeoutException('timeout'),
      );
      final coordinator = GoLiveCoordinator(controller: fake);
      await coordinator.initialize();
      await coordinator.start(
        roomId: 'room-1',
        accessToken: 'token',
      );
      expect(
        coordinator.state.phase,
        YohPalStreamingPhase.failed,
      );
    },
  );

  test('viewer count stream updates state', () async {
    final fake = FakeBroadcasterController();
    final coordinator = GoLiveCoordinator(controller: fake);
    await coordinator.initialize();
    fake.viewerCounts.add(17);
    await Future<void>.delayed(Duration.zero);
    expect(coordinator.state.viewerCount, 17);
  });
}

final class FakeBroadcasterController implements YohPalBroadcasterContract {
  FakeBroadcasterController({
    this.startError,
  });

  final Object? startError;
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final viewerCounts = StreamController<int>.broadcast();
  final disconnects = StreamController<void>.broadcast();
  bool started = false;

  @override
  RTCVideoRenderer get localRenderer => _renderer;

  @override
  Stream<int> get viewerCountStream => viewerCounts.stream;

  @override
  Stream<void> get disconnectedStream => disconnects.stream;

  @override
  Future<void> startBroadcast({
    required String roomId,
    required String accessToken,
  }) async {
    if (startError != null) throw startError!;
    started = true;
  }

  @override
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  }) async {}

  @override
  Future<void> stopBroadcast() async {
    started = false;
  }

  @override
  Future<void> dispose() async {
    await viewerCounts.close();
    await disconnects.close();
    await _renderer.dispose();
  }
}
