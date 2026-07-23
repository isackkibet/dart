import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:yohpal_live_streaming/src/contracts/streaming_controller_contracts.dart';
import 'package:yohpal_live_streaming/src/ui/go_live_screen.dart';
import 'package:yohpal_live_streaming/src/ui/live_viewer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('FlutterWebRTC.Method'),
      (MethodCall methodCall) async => <String, dynamic>{'textureId': 0},
    );
  });

  group('GoLiveScreen', () {
    testWidgets(
      'LS2A-UI-01 Go Live shows connecting state',
      (tester) async {
        final completer = Completer<void>();
        final controller = FakeBroadcasterWC(
          startCompleter: completer,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: GoLiveScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        );
        completer.complete();
        await tester.pump();
        await tester.pump();
      },
    );

    testWidgets(
      'LS2A-UI-02 Go Live shows LIVE state',
      (tester) async {
        final controller = FakeBroadcasterWC();
        await tester.pumpWidget(
          MaterialApp(
            home: GoLiveScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(find.text('End Live'), findsOneWidget);
      },
    );

    testWidgets(
      'LS2A-UI-03 Go Live shows viewer count',
      (tester) async {
        final controller = FakeBroadcasterWC();
        await tester.pumpWidget(
          MaterialApp(
            home: GoLiveScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        controller.viewerSink.add(42);
        await tester.pump();
        await tester.pump();
        expect(
          find.text('42 viewers'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'LS2A-UI-04 Go Live displays retry after timeout',
      (tester) async {
        final controller = FakeBroadcasterWC(
          goLiveError: TimeoutException('timeout'),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: GoLiveScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(find.text('Try again'), findsOneWidget);
      },
    );

    testWidgets(
      'LS2A-UI-05 End Live requires confirmation',
      (tester) async {
        final controller = FakeBroadcasterWC();
        await tester.pumpWidget(
          MaterialApp(
            home: GoLiveScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        final navigator = Navigator.of(
          tester.element(find.byType(GoLiveScreen)),
        );
        navigator.maybePop();
        await tester.pumpAndSettle();
        expect(
          find.text('End live stream?'),
          findsOneWidget,
        );
      },
    );
  });

  group('LiveViewerScreen', () {
    testWidgets(
      'LS2A-UI-06 Viewer shows loading state',
      (tester) async {
        final completer = Completer<void>();
        final controller = FakeViewerWC(
          joinCompleter: completer,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: LiveViewerScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
              chatEnabled: false,
              giftsEnabled: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        );
        completer.complete();
        await tester.pump();
        await tester.pump();
      },
    );

    testWidgets(
      'LS2A-UI-07 Viewer displays remote renderer',
      (tester) async {
        final controller = FakeViewerWC();
        await tester.pumpWidget(
          MaterialApp(
            home: LiveViewerScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
              chatEnabled: false,
              giftsEnabled: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(
          find.byType(RTCVideoView),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'LS2A-UI-08 Viewer displays reconnect state',
      (tester) async {
        final reconnectCompleter = Completer<void>();
        final controller = FakeViewerWC(
          reconnectCompleter: reconnectCompleter,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: LiveViewerScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
              chatEnabled: false,
              giftsEnabled: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        controller.disconnectSink.add(null);
        await tester.pump();
        await tester.pump();
        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        );
        reconnectCompleter.complete();
        await tester.pump();
        await tester.pump();
      },
    );

    testWidgets(
      'LS2A-UI-09 Viewer displays ended state',
      (tester) async {
        final controller = FakeViewerWC();
        await tester.pumpWidget(
          MaterialApp(
            home: LiveViewerScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
              chatEnabled: false,
              giftsEnabled: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        controller.endedSink.add(null);
        await tester.pump();
        await tester.pump();
        expect(
          find.text(
            'This live stream has ended.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'LS2A-UI-10 Chat hidden when feature flag is off',
      (tester) async {
        final controller = FakeViewerWC();
        await tester.pumpWidget(
          MaterialApp(
            home: LiveViewerScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
              chatEnabled: false,
              giftsEnabled: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(find.byType(TextField), findsNothing);
      },
    );

    testWidgets(
      'LS2A-UI-11 Gift hidden when feature flag is off',
      (tester) async {
        final controller = FakeViewerWC();
        await tester.pumpWidget(
          MaterialApp(
            home: LiveViewerScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
              chatEnabled: false,
              giftsEnabled: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(find.text('Gift'), findsNothing);
      },
    );

    testWidgets(
      'LS2A-UI-14 Screen disposal closes RTC resources',
      (tester) async {
        final controller = FakeViewerWC();
        await tester.pumpWidget(
          MaterialApp(
            home: LiveViewerScreen(
              roomId: 'room-1',
              accessToken: 'tok',
              controllerFactory: () => controller,
              chatEnabled: false,
              giftsEnabled: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold()),
        );
        expect(controller.disposed, isTrue);
      },
    );
  });
}

class FakeBroadcasterWC implements YohPalBroadcasterContract {
  FakeBroadcasterWC({
    this.goLiveError,
    this.startCompleter,
  });

  final Object? goLiveError;
  final Completer<void>? startCompleter;
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final _viewerCounts = StreamController<int>.broadcast();
  final _disconnects = StreamController<void>.broadcast();

  @override
  RTCVideoRenderer get localRenderer => _renderer;

  StreamSink<int> get viewerSink => _viewerCounts.sink;

  @override
  Stream<int> get viewerCountStream => _viewerCounts.stream;

  @override
  Stream<void> get disconnectedStream => _disconnects.stream;

  @override
  Future<void> startBroadcast({
    required String roomId,
    required String accessToken,
  }) async {
    if (startCompleter != null) {
      await startCompleter!.future;
    }
    if (goLiveError != null) throw goLiveError!;
  }

  @override
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  }) async {}

  @override
  Future<void> stopBroadcast() async {}

  @override
  Future<void> dispose() async {
    await _viewerCounts.close();
    await _disconnects.close();
    await _renderer.dispose();
  }
}

class FakeViewerWC implements YohPalViewerContract {
  FakeViewerWC({
    this.joinError,
    this.joinCompleter,
    this.reconnectCompleter,
  });

  final Object? joinError;
  final Completer<void>? joinCompleter;
  final Completer<void>? reconnectCompleter;
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  final _disconnects = StreamController<void>.broadcast();
  final _ended = StreamController<void>.broadcast();

  @override
  RTCVideoRenderer get remoteRenderer => _renderer;

  StreamSink<void> get disconnectSink => _disconnects.sink;

  StreamSink<void> get endedSink => _ended.sink;

  bool disposed = false;

  @override
  Stream<void> get disconnectedStream => _disconnects.stream;

  @override
  Stream<void> get streamEndedStream => _ended.stream;

  @override
  Future<void> joinStream({
    required String roomId,
    required String accessToken,
  }) async {
    if (joinCompleter != null) {
      await joinCompleter!.future;
    }
    if (joinError != null) throw joinError!;
  }

  @override
  Future<void> leaveStream() async {}

  @override
  Future<void> reconnect({
    required String roomId,
    required String accessToken,
  }) async {
    if (reconnectCompleter != null) {
      await reconnectCompleter!.future;
    }
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _disconnects.close();
    await _ended.close();
    await _renderer.dispose();
  }
}
