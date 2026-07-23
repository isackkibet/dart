import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/presentation/video_timestamp.dart';

void main() {
  group('formatVideoTimestamp', () {
    final anchor = DateTime(2026, 7, 14, 12, 0);

    test('just now when under a minute', () {
      expect(
        formatVideoTimestamp(DateTime(2026, 7, 14, 11, 59, 30), now: anchor),
        'Just now',
      );
    });

    test('5m ago', () {
      expect(
        formatVideoTimestamp(DateTime(2026, 7, 14, 11, 55), now: anchor),
        '5m ago',
      );
    });

    test('hours ago', () {
      expect(
        formatVideoTimestamp(DateTime(2026, 7, 14, 9, 0), now: anchor),
        '3h ago',
      );
    });

    test('yesterday', () {
      expect(
        formatVideoTimestamp(DateTime(2026, 7, 13, 6, 0), now: anchor),
        'Yesterday',
      );
    });

    test('days ago within a week', () {
      expect(
        formatVideoTimestamp(DateTime(2026, 7, 10, 12, 0), now: anchor),
        '4d ago',
      );
    });

    test('formatted date beyond a week', () {
      expect(
        formatVideoTimestamp(DateTime(2026, 7, 1, 12, 0), now: anchor),
        '01/07/2026',
      );
    });
  });

  group('VideoTimestamp widget', () {
    testWidgets('renders relative label from DateTime', (tester) async {
      final publishedAt = DateTime.now().subtract(const Duration(minutes: 5));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VideoTimestamp(publishedAt: publishedAt)),
        ),
      );
      expect(find.byKey(const ValueKey('video-timestamp')), findsOneWidget);
      expect(find.textContaining('m ago'), findsOneWidget);
    });

    testWidgets('has correct ValueKey', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoTimestamp(publishedAt: DateTime(2026, 1, 1)),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('video-timestamp')), findsOneWidget);
    });
  });

  group('VideoTimestampOverlay', () {
    testWidgets('renders inside Positioned with publishedAt', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                VideoTimestampOverlay(
                  publishedAt: DateTime(2026, 7, 14, 11, 55),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(Positioned), findsOneWidget);
      expect(find.byType(VideoTimestamp), findsOneWidget);
    });
  });
}
