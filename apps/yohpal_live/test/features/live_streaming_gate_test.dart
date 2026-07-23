import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live/features/live_streaming/live_streaming_flags.dart';
import 'package:yohpal_live/features/live_streaming/live_streaming_gate.dart';
import 'package:flutter/material.dart';

void main() {
  test('LiveStreamingFlags defaults', () {
    expect(LiveStreamingFlags.enabled, false);
    expect(LiveStreamingFlags.giftsEnabled, false);
    expect(LiveStreamingFlags.chatEnabled, true);
  });

  testWidgets('LiveStreamingGate blocks when disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LiveStreamingGate(
          child: Text('Allowed'),
        ),
      ),
    );
    expect(find.text('Live Streaming is coming soon.'), findsOneWidget);
    expect(find.text('Allowed'), findsNothing);
  });
}
