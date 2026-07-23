import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/controllers/feed_category_controller.dart';
import 'package:yohpal_live_v2/features/feed/domain/feed_category.dart';
import 'package:yohpal_live_v2/features/feed/presentation/feed_category_selector.dart';

void main() {
  // ── IOS-FEED-01: Recommended category visible ────────────────────────────
  group('IOS-FEED-01 — Recommended category visible', () {
    testWidgets('FeedCategorySelector shows Recommended', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: FeedCategorySelector(
              selected: FeedCategory.recommended,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Recommended'), findsOneWidget);
    });
  });

  // ── IOS-FEED-02: Following category visible ──────────────────────────────
  group('IOS-FEED-02 — Following category visible', () {
    testWidgets('FeedCategorySelector shows Following', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: FeedCategorySelector(
              selected: FeedCategory.recommended,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets(
        'iOS feed displays Recommended and Following categories',
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
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
    });
  });

  // ── IOS-FEED-03: Category switching works ────────────────────────────────
  group('IOS-FEED-03 — category switching works', () {
    testWidgets('tapping Following fires onSelected with following',
        (tester) async {
      FeedCategory? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: FeedCategorySelector(
              selected: FeedCategory.recommended,
              onSelected: (cat) => selected = cat,
            ),
          ),
        ),
      );
      await tester.tap(
          find.byKey(const ValueKey('feed-category-following')));
      expect(selected, FeedCategory.following);
    });

    testWidgets('tapping Recommended fires onSelected with recommended',
        (tester) async {
      FeedCategory? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.black,
            body: FeedCategorySelector(
              selected: FeedCategory.following,
              onSelected: (cat) => selected = cat,
            ),
          ),
        ),
      );
      await tester.tap(
          find.byKey(const ValueKey('feed-category-recommended')));
      expect(selected, FeedCategory.recommended);
    });
  });

  // ── FeedCategoryController unit tests ────────────────────────────────────
  group('FeedCategoryController', () {
    test('defaults to recommended', () {
      final controller = FeedCategoryController();
      expect(controller.selected, FeedCategory.recommended);
      controller.dispose();
    });

    test('select changes category and notifies listeners', () {
      final controller = FeedCategoryController();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.select(FeedCategory.following);
      expect(controller.selected, FeedCategory.following);
      expect(notified, isTrue);
      controller.dispose();
    });

    test('selecting the same category does not notify', () {
      final controller = FeedCategoryController();
      var count = 0;
      controller.addListener(() => count++);
      controller.select(FeedCategory.recommended);
      expect(count, 0);
      controller.dispose();
    });
  });
}
