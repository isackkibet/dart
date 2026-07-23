import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/controllers/feed_inventory_coordinator.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/data/zero_wait_feed_repository.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/models/preload_video.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/storage/feed_inventory_store.dart';

// ── In-memory stubs ────────────────────────────────────────────────────────

class _FakeRepo implements ZeroWaitFeedRepository {
  _FakeRepo(this._videos);
  final List<PreloadVideo> _videos;
  int _cursor = 0;

  @override
  Future<FeedPage> fetchPage({required int limit, String? cursor}) async {
    if (cursor != null || _cursor == 0) {
      _cursor = 0;
    }
    final start = cursor != null ? int.tryParse(cursor) ?? _cursor : _cursor;
    final page = _videos.skip(start).take(limit).toList();
    _cursor = start + page.length;
    return FeedPage(
      videos: page,
      nextCursor: _cursor < _videos.length ? _cursor.toString() : null,
      hasMore: _cursor < _videos.length,
    );
  }
}

class _FakeStore implements FeedInventoryStore {
  List<PreloadVideo> _stored = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<List<PreloadVideo>> readAll() async => List.of(_stored);

  @override
  Future<void> replaceAll(List<PreloadVideo> videos) async =>
      _stored = List.of(videos);

  @override
  Future<int> count() async => _stored.length;

  @override
  Future<void> clear() async => _stored = [];
}

List<PreloadVideo> _makeVideos(int count) => List.generate(
      count,
      (i) => PreloadVideo(
        id: 'v$i',
        feedIndex: i,
        thumbnailUrl: 'https://cdn.example.com/v$i.jpg',
        videoUrl: 'https://cdn.example.com/v$i.mp4',
      ),
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('FeedInventoryCoordinator', () {
    late _FakeRepo repo;
    late _FakeStore store;
    late FeedInventoryCoordinator coordinator;

    setUp(() {
      repo = _FakeRepo(_makeVideos(150));
      store = _FakeStore();
      coordinator = FeedInventoryCoordinator(repository: repo, store: store);
    });

    test('ensureRunway fetches exactly targetInventory items', () async {
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 100,
        targetInventory: 100,
      );
      expect(coordinator.length, 100);
    });

    test('ensureRunway assigns contiguous feedIndex values', () async {
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 10,
        targetInventory: 10,
      );
      for (int i = 0; i < 10; i++) {
        expect(coordinator[i]!.feedIndex, i);
      }
    });

    test('ensureRunway fetches more when below minimumAhead', () async {
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 20,
        targetInventory: 20,
      );
      expect(coordinator.length, 20);

      // Simulate user at index 18 — only 2 videos ahead, minimum is 10.
      await coordinator.ensureRunway(
        currentIndex: 18,
        minimumAhead: 10,
        targetInventory: 50,
      );
      expect(coordinator.length, greaterThan(20));
    });

    test('ensureRunway deduplicates on repeated calls', () async {
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 30,
        targetInventory: 30,
      );
      final before = coordinator.length;

      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 5,
        targetInventory: 30,
      );
      expect(coordinator.length, before);
    });

    test('ensureRunway restores persisted inventory on first call', () async {
      // Seed the store with 10 videos.
      final seed = _makeVideos(10);
      await store.replaceAll(seed);
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 1,
        targetInventory: 10,
      );
      expect(coordinator.length, 10);
    });

    test('clear empties inventory and store', () async {
      await coordinator.ensureRunway(
        currentIndex: 0,
        minimumAhead: 20,
        targetInventory: 20,
      );
      await coordinator.clearSession();
      expect(coordinator.length, 0);
      expect((await store.readAll()).length, 0);
    });
  });
}
