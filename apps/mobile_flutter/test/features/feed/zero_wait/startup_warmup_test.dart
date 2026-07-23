import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/controllers/feed_inventory_coordinator.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/data/zero_wait_feed_repository.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/models/preload_video.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/policy/zero_wait_buffer_policy.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/storage/feed_inventory_store.dart';

// ── Stubs ──────────────────────────────────────────────────────────────────

class _FakeRepo implements ZeroWaitFeedRepository {
  final List<PreloadVideo> videos;
  _FakeRepo(this.videos);

  @override
  Future<FeedPage> fetchPage({required int limit, String? cursor}) async =>
      FeedPage(
        videos: videos.take(limit).toList(),
        nextCursor: limit < videos.length ? 'cursor' : null,
        hasMore: limit < videos.length,
      );
}

class _FakeStore implements FeedInventoryStore {
  @override
  Future<void> initialize() async {}
  @override
  Future<List<PreloadVideo>> readAll() async => [];
  @override
  Future<void> replaceAll(List<PreloadVideo> videos) async {}
  @override
  Future<int> count() async => 0;
  @override
  Future<void> clear() async {}
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('FeedStartupWarmupService (coordinator unit)', () {
    test('ensureRunway produces exactly 100 items from a 120-video repo', () async {
      final videos = List.generate(
        120,
        (i) => PreloadVideo(
          id: 'v$i',
          feedIndex: i,
          thumbnailUrl: 'https://cdn.example.com/$i.jpg',
          videoUrl: 'https://cdn.example.com/$i.mp4',
        ),
      );
      final coordinator = FeedInventoryCoordinator(
        repository: _FakeRepo(videos),
        store: _FakeStore(),
      );
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 100,
        targetInventory: 100,
      );
      expect(coordinator.length, 100);
    });

    test('policy lookup returns non-null for every matrix cell', () {
      for (final net in YohPalNetworkClass.values) {
        for (final dev in YohPalDeviceClass.values) {
          final policy = ZeroWaitBufferPolicy.resolve(network: net, device: dev);
          expect(policy, isNotNull, reason: 'net=$net dev=$dev');
          expect(policy.hotControllerCount, greaterThan(0), reason: 'net=$net dev=$dev');
        }
      }
    });

    test('inventory indices are contiguous after ensureRunway', () async {
      final videos = List.generate(
        50,
        (i) => PreloadVideo(
          id: 'v$i',
          feedIndex: i,
          thumbnailUrl: 'https://cdn.example.com/$i.jpg',
          videoUrl: 'https://cdn.example.com/$i.mp4',
        ),
      );
      final coordinator = FeedInventoryCoordinator(
        repository: _FakeRepo(videos),
        store: _FakeStore(),
      );
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 50,
        targetInventory: 50,
      );
      for (int i = 0; i < coordinator.length; i++) {
        expect(coordinator[i]!.feedIndex, i, reason: 'index $i');
      }
    });

    test('ensureRunway is idempotent when inventory already at target', () async {
      final videos = List.generate(
        100,
        (i) => PreloadVideo(
          id: 'v$i',
          feedIndex: i,
          thumbnailUrl: 'https://cdn.example.com/$i.jpg',
          videoUrl: 'https://cdn.example.com/$i.mp4',
        ),
      );
      final coordinator = FeedInventoryCoordinator(
        repository: _FakeRepo(videos),
        store: _FakeStore(),
      );
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 100,
        targetInventory: 100,
      );
      final sizeAfterFirst = coordinator.length;
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 100,
        targetInventory: 100,
      );
      expect(coordinator.length, sizeAfterFirst);
    });
  });
}
