import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/domain/viewer_video_exposure.dart';

void main() {
  final baseExposure = ViewerVideoExposure(
    viewerId: 'viewer-001',
    videoId: 'video-001',
    firstShownAt: DateTime(2026, 7, 15, 10),
    lastShownAt: DateTime(2026, 7, 15, 10, 1),
    maximumProgressPercent: 0,
    source: 'recommended',
    automaticFeedEligible: true,
  );

  // ── FEED-NR-01: Completed video excluded ─────────────────────────────────
  group('FEED-NR-01 — completed video excluded from recommendations', () {
    test('excludes video when completedAt is set', () {
      final result = canAutomaticallyRecommendVideo(
        viewerId: 'viewer-001',
        creatorId: 'creator-001',
        requestedSource: 'recommended',
        exposure: ViewerVideoExposure(
          viewerId: 'viewer-001',
          videoId: 'video-001',
          firstShownAt: baseExposure.firstShownAt,
          lastShownAt: baseExposure.lastShownAt,
          completedAt: DateTime(2026, 7, 15, 10, 1, 30),
          maximumProgressPercent: 100,
          source: 'recommended',
          automaticFeedEligible: false,
        ),
      );
      expect(result, isFalse);
    });

    test('excludes video watched past 80%', () {
      final result = canAutomaticallyRecommendVideo(
        viewerId: 'viewer-001',
        creatorId: 'creator-001',
        requestedSource: 'recommended',
        exposure: ViewerVideoExposure(
          viewerId: 'viewer-001',
          videoId: 'video-001',
          firstShownAt: baseExposure.firstShownAt,
          lastShownAt: baseExposure.lastShownAt,
          maximumProgressPercent: 82,
          source: 'recommended',
          automaticFeedEligible: false,
        ),
      );
      expect(result, isFalse);
    });

    test('allows video with low progress to reappear', () {
      final result = canAutomaticallyRecommendVideo(
        viewerId: 'viewer-001',
        creatorId: 'creator-001',
        requestedSource: 'recommended',
        exposure: ViewerVideoExposure(
          viewerId: 'viewer-001',
          videoId: 'video-001',
          firstShownAt: baseExposure.firstShownAt,
          lastShownAt: baseExposure.lastShownAt,
          maximumProgressPercent: 30,
          source: 'recommended',
          automaticFeedEligible: true,
        ),
      );
      expect(result, isTrue);
    });
  });

  // ── FEED-NR-02: Search permits intentional replay ─────────────────────────
  group('FEED-NR-02 — search permits intentional replay', () {
    test('search source allows a completed video', () {
      final result = canAutomaticallyRecommendVideo(
        viewerId: 'viewer-001',
        creatorId: 'creator-001',
        requestedSource: 'search',
        exposure: ViewerVideoExposure(
          viewerId: 'viewer-001',
          videoId: 'video-001',
          firstShownAt: baseExposure.firstShownAt,
          lastShownAt: baseExposure.lastShownAt,
          completedAt: DateTime(2026, 7, 15, 10, 1, 30),
          maximumProgressPercent: 100,
          source: 'recommended',
          automaticFeedEligible: false,
        ),
      );
      expect(result, isTrue);
    });

    test('liked source allows a completed video', () {
      final result = canAutomaticallyRecommendVideo(
        viewerId: 'viewer-001',
        creatorId: 'creator-001',
        requestedSource: 'liked',
        exposure: ViewerVideoExposure(
          viewerId: 'viewer-001',
          videoId: 'video-001',
          firstShownAt: baseExposure.firstShownAt,
          lastShownAt: baseExposure.lastShownAt,
          completedAt: DateTime(2026, 7, 15, 10, 1, 30),
          maximumProgressPercent: 100,
          source: 'recommended',
          automaticFeedEligible: false,
        ),
      );
      expect(result, isTrue);
    });
  });

  // ── FEED-NR-03: Swipe-back permits replay ────────────────────────────────
  group('FEED-NR-03 — swipe-back permits replay', () {
    test('swipe_back source bypasses exclusion', () {
      final result = canAutomaticallyRecommendVideo(
        viewerId: 'viewer-001',
        creatorId: 'creator-001',
        requestedSource: 'swipe_back',
        exposure: ViewerVideoExposure(
          viewerId: 'viewer-001',
          videoId: 'video-001',
          firstShownAt: baseExposure.firstShownAt,
          lastShownAt: baseExposure.lastShownAt,
          completedAt: DateTime(2026, 7, 15, 10, 1, 30),
          maximumProgressPercent: 100,
          source: 'recommended',
          automaticFeedEligible: false,
        ),
      );
      expect(result, isTrue);
    });
  });

  // ── FEED-NR-04: Exposure survives restart (data model) ────────────────────
  group('FEED-NR-04 — ViewerVideoExposure serialises and deserialises', () {
    test('toMap / fromMap round-trip preserves all fields', () {
      final original = ViewerVideoExposure(
        viewerId: 'viewer-001',
        videoId: 'video-001',
        firstShownAt: DateTime(2026, 7, 15, 10),
        lastShownAt: DateTime(2026, 7, 15, 10, 1),
        completedAt: DateTime(2026, 7, 15, 10, 1, 30),
        maximumProgressPercent: 95.5,
        source: 'recommended',
        automaticFeedEligible: false,
      );

      final restored = ViewerVideoExposure.fromMap(original.toMap());

      expect(restored.viewerId, original.viewerId);
      expect(restored.videoId, original.videoId);
      expect(restored.maximumProgressPercent,
          original.maximumProgressPercent);
      expect(restored.automaticFeedEligible, original.automaticFeedEligible);
      expect(restored.completedAt, original.completedAt);
    });

    test('fromMap handles missing completedAt', () {
      final exposure = ViewerVideoExposure(
        viewerId: 'viewer-001',
        videoId: 'video-002',
        firstShownAt: DateTime(2026, 7, 15, 10),
        lastShownAt: DateTime(2026, 7, 15, 10, 1),
        maximumProgressPercent: 40,
        source: 'following',
        automaticFeedEligible: true,
      );

      final restored = ViewerVideoExposure.fromMap(exposure.toMap());
      expect(restored.completedAt, isNull);
      expect(restored.automaticFeedEligible, isTrue);
    });
  });
}
