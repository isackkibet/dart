import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/domain/feed_category.dart';
import 'package:yohpal_live_v2/features/feed/presentation/feed_category_selector.dart';

void main() {
  // ── RC2-IOS-FEED-001 / RC2-AND-FEED-001: Parity ─────────────────────────
  group('FeedCategorySelector — iOS and Android parity (RC2-IOS-FEED-001…007)', () {
    testWidgets('Recommended and Following labels are both present',
        (tester) async {
      FeedCategory? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCategorySelector(
              selected: FeedCategory.recommended,
              onSelected: (category) => selected = category,
            ),
          ),
        ),
      );

      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);

      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(selected, FeedCategory.following);
    });

    testWidgets('Tapping Recommended fires onSelected with recommended',
        (tester) async {
      FeedCategory? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCategorySelector(
              selected: FeedCategory.following,
              onSelected: (category) => selected = category,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Recommended'));
      await tester.pumpAndSettle();
      expect(selected, FeedCategory.recommended);
    });

    testWidgets('Selector uses ValueKeys for both categories', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCategorySelector(
              selected: FeedCategory.recommended,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('feed-category-recommended')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('feed-category-following')),
        findsOneWidget,
      );
    });

    testWidgets('Selector is wrapped in SafeArea for notch safety',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCategorySelector(
              selected: FeedCategory.recommended,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('Selector has Semantics container for VoiceOver/TalkBack',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedCategorySelector(
              selected: FeedCategory.recommended,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(find.byType(Semantics).first);
      expect(semantics.container, isTrue);
    });

    testWidgets('Selected category indicator changes when selection changes',
        (tester) async {
      FeedCategory current = FeedCategory.recommended;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Scaffold(
              body: FeedCategorySelector(
                selected: current,
                onSelected: (category) => setState(() => current = category),
              ),
            ),
          ),
        ),
      );

      // Initially Recommended is selected — tap Following.
      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(current, FeedCategory.following);

      // Tap back to Recommended.
      await tester.tap(find.text('Recommended'));
      await tester.pumpAndSettle();
      expect(current, FeedCategory.recommended);
    });
  });
}
