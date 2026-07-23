import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_streaming/yohpal_live_streaming.dart';

final class FailingLiveGiftService implements LiveGiftContract {
  @override
  Future<LiveGiftReceipt> sendGift({
    required String liveSessionId,
    required String giftId,
  }) async {
    throw StateError('Simulated gift failure');
  }
}

void main() {
  testWidgets(
    'LS2A-UI-13 displays clear feedback when gift transaction fails',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveGiftButton(
              liveSessionId: 'live-session-001',
              service: FailingLiveGiftService(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LiveGiftButton));
      await tester.pumpAndSettle();

      final roseByKey = find.byKey(
        const ValueKey<String>('gift-option-rose'),
      );

      if (roseByKey.evaluate().isNotEmpty) {
        await tester.tap(roseByKey);
      } else {
        await tester.tap(find.text('Rose'));
      }

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Gift could not be sent'), findsOneWidget);
    },
  );
}
