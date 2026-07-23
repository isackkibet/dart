import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_streaming/src/signaling/yohpal_signaling_client.dart';
import 'package:yohpal_live_streaming/src/signaling/yohpal_signaling_transport.dart';

void main() {
  test(
    'request times out and removes pending request',
    () async {
      final transport = SilentFakeSignalingTransport();
      final client = YohPalSignalingClient(
        transport: transport,
      );
      expect(
        () => client.request(
          'createTransport',
          const {},
          timeout: const Duration(milliseconds: 40),
        ),
        throwsA(isA<TimeoutException>()),
      );

      await Future<void>.delayed(
        const Duration(milliseconds: 60),
      );

      expect(client.pendingRequestCount, 0);
    },
  );
}

final class SilentFakeSignalingTransport implements YohPalSignalingTransport {
  final StreamController<dynamic> _messages =
      StreamController<dynamic>.broadcast();
  final StreamController<Object> _errors = StreamController<Object>.broadcast();

  @override
  Stream<dynamic> get messages => _messages.stream;

  @override
  Stream<Object> get errors => _errors.stream;

  @override
  void send(String message) {}

  @override
  Future<void> close() async {
    await _messages.close();
    await _errors.close();
  }
}
