import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_streaming/yohpal_live_streaming.dart';

final class FailingLiveChatRepository implements LiveChatContract {
  @override
  Stream<List<LiveChatMessage>> watchMessages({
    required String liveSessionId,
  }) {
    return Stream<List<LiveChatMessage>>.value(
      const <LiveChatMessage>[],
    );
  }

  @override
  Future<void> sendMessage({
    required String liveSessionId,
    required String text,
  }) async {
    throw StateError('Simulated chat failure');
  }
}

void main() {
  testWidgets(
    'LS2A-UI-12 retains failed chat message and displays retry feedback',
    (WidgetTester tester) async {
      const message = 'Please keep this message';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveChatPanel(
              liveSessionId: 'live-session-001',
              repository: FailingLiveChatRepository(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);

      await tester.enterText(inputFinder, message);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(inputFinder);
      expect(textField.controller?.text, message);
      expect(find.textContaining('Message failed'), findsOneWidget);
    },
  );
}
