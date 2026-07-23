import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/creator_profile/domain/creator_library_category.dart';
import 'package:yohpal_live_v2/features/creator_profile/domain/creator_profile_video.dart';
import 'package:yohpal_live_v2/features/creator_profile/widgets/creator_identity_block.dart';
import 'package:yohpal_live_v2/features/creator_profile/widgets/creator_library_tabs.dart';
import 'package:yohpal_live_v2/features/creator_profile/widgets/creator_video_grid.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

Widget _wrapScroll(List<Widget> slivers) => MaterialApp(
      home: Scaffold(
        body: CustomScrollView(slivers: slivers),
      ),
    );

CreatorProfileVideo _video(String id, {int views = 100}) =>
    CreatorProfileVideo(
      id: id,
      thumbnailUrl: '',
      views: views,
      visibility: 'public',
      publishedAt: DateTime(2026, 7, 1),
      processingStatus: 'published',
    );

void main() {
  // ── PROFILE-UI-01: Display name visible ──────────────────────────────────
  group('PROFILE-UI-01 — display name visible', () {
    testWidgets('CreatorIdentityBlock shows display name', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CreatorIdentityBlock(
            displayName: 'Amara Osei',
            username: 'amaraosei',
            verified: false,
            onOpenProfile: () {},
          ),
        ),
      );
      expect(find.text('Amara Osei'), findsOneWidget);
    });
  });

  // ── PROFILE-UI-02: Username visible ──────────────────────────────────────
  group('PROFILE-UI-02 — username visible', () {
    testWidgets('CreatorIdentityBlock shows @username', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CreatorIdentityBlock(
            displayName: 'Amara Osei',
            username: 'amaraosei',
            verified: false,
            onOpenProfile: () {},
          ),
        ),
      );
      expect(find.text('@amaraosei'), findsOneWidget);
    });

    testWidgets('verified badge appears when verified is true',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CreatorIdentityBlock(
            displayName: 'Verified Creator',
            username: 'vcreator',
            verified: true,
            onOpenProfile: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('verified badge is absent when verified is false',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CreatorIdentityBlock(
            displayName: 'Regular Creator',
            username: 'rcreator',
            verified: false,
            onOpenProfile: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('tapping identity fires onOpenProfile callback',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          CreatorIdentityBlock(
            displayName: 'Amara Osei',
            username: 'amaraosei',
            verified: false,
            onOpenProfile: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('creator-identity-block')));
      expect(tapped, isTrue);
    });
  });

  // ── PROFILE-UI-03: Video grid populated ──────────────────────────────────
  group('PROFILE-UI-03 — video grid populated', () {
    testWidgets('CreatorVideoGrid renders thumbnails for each video',
        (tester) async {
      final videos = [_video('v1'), _video('v2'), _video('v3')];

      await tester.pumpWidget(
        _wrapScroll([
          CreatorVideoGrid(
            videos: videos,
            loading: false,
            error: null,
            hasMore: false,
            onRetry: () {},
            onLoadMore: () {},
            onOpenVideo: (_) {},
          ),
        ]),
      );

      expect(find.byKey(const ValueKey('creator-video-v1')), findsOneWidget);
      expect(find.byKey(const ValueKey('creator-video-v2')), findsOneWidget);
      expect(find.byKey(const ValueKey('creator-video-v3')), findsOneWidget);
    });
  });

  // ── PROFILE-UI-04: Video grid empty state ────────────────────────────────
  group('PROFILE-UI-04 — video grid empty state', () {
    testWidgets('CreatorVideoGrid shows empty message when videos is empty',
        (tester) async {
      await tester.pumpWidget(
        _wrapScroll([
          CreatorVideoGrid(
            videos: const [],
            loading: false,
            error: null,
            hasMore: false,
            onRetry: () {},
            onLoadMore: () {},
            onOpenVideo: (_) {},
          ),
        ]),
      );
      expect(find.text('No videos in this category.'), findsOneWidget);
    });

    testWidgets(
        'CreatorVideoGrid shows loading skeleton when loading is true',
        (tester) async {
      await tester.pumpWidget(
        _wrapScroll([
          CreatorVideoGrid(
            videos: const [],
            loading: true,
            error: null,
            hasMore: false,
            onRetry: () {},
            onLoadMore: () {},
            onOpenVideo: (_) {},
          ),
        ]),
      );
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('CreatorVideoGrid shows retry button on error',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrapScroll([
          CreatorVideoGrid(
            videos: const [],
            loading: false,
            error: Exception('network error'),
            hasMore: false,
            onRetry: () => retried = true,
            onLoadMore: () {},
            onOpenVideo: (_) {},
          ),
        ]),
      );
      expect(find.text('Videos could not be loaded.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });

  // ── PROFILE-UI-05: Owner categories visible ──────────────────────────────
  group('PROFILE-UI-05 — owner library categories', () {
    testWidgets('CreatorLibraryTabs shows all categories for owner',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CreatorLibraryTabs(
            isOwner: true,
            selected: CreatorLibraryCategory.publicVideos,
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
      final chipCount =
          tester.widgetList(find.byType(ChoiceChip)).length;
      expect(chipCount, greaterThan(2));
    });

    testWidgets('CreatorLibraryTabs shows only public tabs for non-owner',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CreatorLibraryTabs(
            isOwner: false,
            selected: CreatorLibraryCategory.publicVideos,
            onSelected: (_) {},
          ),
        ),
      );
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Drafts'), findsNothing);
      expect(find.text('Private'), findsNothing);
    });
  });
}
