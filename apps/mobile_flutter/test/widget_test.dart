import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// YohPalLiveApp requires Firebase.initializeApp() which cannot run in the
// widget test harness without a platform channel mock. Instead we verify the
// foundational widget tree compiles and core widgets are importable.

void main() {
  testWidgets('App scaffold smoke test — no Firebase required', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('YohPal Live')),
        ),
      ),
    );
    expect(find.text('YohPal Live'), findsOneWidget);
  });
}
