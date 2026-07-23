import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/policy/zero_wait_buffer_policy.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/models/preload_video.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/controllers/feed_inventory_coordinator.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/data/zero_wait_feed_repository.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/storage/feed_inventory_store.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeStore implements FeedInventoryStore {
  List<PreloadVideo> _data = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<List<PreloadVideo>> readAll() async => List.of(_data);

  @override
  Future<void> replaceAll(List<PreloadVideo> videos) async {
    _data = List.of(videos);
  }

  @override
  Future<int> count() async => _data.length;

  @override
  Future<void> clear() async => _data = [];
}

class _FakeRepository implements ZeroWaitFeedRepository {
  _FakeRepository({required this.totalVideos});
  final int totalVideos;
  int _offset = 0;
  int fetchCalled = 0;

  @override
  Future<FeedPage> fetchPage({required int limit, String? cursor}) async {
    if (cursor == null) _offset = 0;
    fetchCalled++;
    final start = _offset;
    final end = (start + limit).clamp(0, totalVideos);
    _offset = end;
    final videos = List.generate(
      end - start,
      (i) => PreloadVideo(
        id: 'v${start + i}',
        feedIndex: start + i,
        thumbnailUrl: '',
        videoUrl: 'https://example.com/v${start + i}.mp4',
      ),
    );
    return FeedPage(
      videos: videos,
      nextCursor: _offset < totalVideos ? _offset.toString() : null,
      hasMore: _offset < totalVideos,
    );
  }
}

// ── Policy tests ──────────────────────────────────────────────────────────────

void main() {
  group('ZeroWaitBufferPolicy', () {
    test('every online network maintains at least 100 minimum runway', () {
      for (final network in YohPalNetworkClass.values) {
        if (network == YohPalNetworkClass.offline) continue;
        final policy = ZeroWaitBufferPolicy.resolve(
          network: network,
          device: YohPalDeviceClass.standard,
        );
        expect(
          policy.minimumRunway,
          greaterThanOrEqualTo(100),
          reason: '${network.name} minimumRunway must be ≥ 100',
        );
        expect(
          policy.targetInventory,
          greaterThanOrEqualTo(100),
          reason: '${network.name} targetInventory must be ≥ 100',
        );
      }
    });

    test('hot controller count never exceeds 8 on any device/network', () {
      for (final network in YohPalNetworkClass.values) {
        for (final device in YohPalDeviceClass.values) {
          final policy = ZeroWaitBufferPolicy.resolve(
              network: network, device: device);
          expect(
            policy.hotControllerCount,
            lessThanOrEqualTo(8),
            reason:
                '${network.name}×${device.name} hotControllerCount must be ≤ 8',
          );
        }
      }
    });

    test('wifiStrong policy prefers HD and allows max concurrency on high-performance device', () {
      final policy = ZeroWaitBufferPolicy.resolve(
        network: YohPalNetworkClass.wifiStrong,
        device: YohPalDeviceClass.highPerformance,
      );
      expect(policy.preferHd, isTrue);
      expect(policy.previewOnly, isFalse);
      expect(policy.concurrentDownloads, greaterThan(1));
      expect(policy.hotControllerCount, equals(8));
    });

    test('3G and constrained policies use preview-only mode', () {
      for (final network in [
        YohPalNetworkClass.threeG,
        YohPalNetworkClass.constrained,
      ]) {
        final policy = ZeroWaitBufferPolicy.resolve(
          network: network,
          device: YohPalDeviceClass.standard,
        );
        expect(policy.previewOnly, isTrue,
            reason: '${network.name} must use previewOnly');
      }
    });

    test('low-memory device never exceeds 4 hot controllers on any network', () {
      for (final network in YohPalNetworkClass.values) {
        final policy = ZeroWaitBufferPolicy.resolve(
          network: network,
          device: YohPalDeviceClass.lowMemory,
        );
        expect(
          policy.hotControllerCount,
          lessThanOrEqualTo(4),
          reason: '${network.name} lowMemory hotControllerCount must be ≤ 4',
        );
      }
    });

    test('offline policy has zero concurrent downloads', () {
      final policy = ZeroWaitBufferPolicy.resolve(
        network: YohPalNetworkClass.offline,
        device: YohPalDeviceClass.standard,
      );
      expect(policy.concurrentDownloads, equals(0));
    });

    test('wifiWeak still prefers non-preview and non-HD', () {
      final policy = ZeroWaitBufferPolicy.resolve(
        network: YohPalNetworkClass.wifiWeak,
        device: YohPalDeviceClass.standard,
      );
      expect(policy.previewOnly, isFalse);
      expect(policy.preferHd, isFalse);
      expect(policy.minimumRunway, greaterThanOrEqualTo(100));
    });
  });

  // ── Inventory coordinator tests ─────────────────────────────────────────────

  group('FeedInventoryCoordinator', () {
    test('ensureRunway fetches until targetInventory is reached', () async {
      final repo = _FakeRepository(totalVideos: 200);
      final store = _FakeStore();
      final coord = FeedInventoryCoordinator(store: store, repository: repo);

      final inventory = await coord.ensureRunway(
        currentIndex: 0,
        minimumAhead: 100,
        targetInventory: 100,
      );

      expect(inventory.length, greaterThanOrEqualTo(100));
      expect(coord.length, greaterThanOrEqualTo(100));
    });

    test('ensureRunway fetches more when runway falls below minimumAhead', () async {
      final repo = _FakeRepository(totalVideos: 300);
      final store = _FakeStore();
      final coord = FeedInventoryCoordinator(store: store, repository: repo);

      // Initial load.
      await coord.ensureRunway(
          currentIndex: 0, minimumAhead: 50, targetInventory: 50);
      final fetchBefore = repo.fetchCalled;

      // Advance index so runway falls below minimumAhead.
      await coord.ensureRunway(
          currentIndex: 40, minimumAhead: 100, targetInventory: 150);

      expect(repo.fetchCalled, greaterThan(fetchBefore));
      expect(coord.length, greaterThanOrEqualTo(100));
    });

    test('de-duplicates videos by id on merge', () async {
      final repo = _FakeRepository(totalVideos: 200);
      final store = _FakeStore();
      final coord = FeedInventoryCoordinator(store: store, repository: repo);

      await coord.ensureRunway(
          currentIndex: 0, minimumAhead: 60, targetInventory: 60);
      // Reset cursor in fake repo by passing null cursor (repo resets offset).
      // Re-run — coordinator should not double-insert.
      await coord.ensureRunway(
          currentIndex: 0, minimumAhead: 60, targetInventory: 60);

      final ids = coord.inventory.map((v) => v.id).toList();
      expect(ids.toSet().length, equals(ids.length),
          reason: 'No duplicate IDs');
    });

    test('feedIndex values are contiguous after merge', () async {
      final repo = _FakeRepository(totalVideos: 200);
      final store = _FakeStore();
      final coord = FeedInventoryCoordinator(store: store, repository: repo);

      await coord.ensureRunway(
          currentIndex: 0, minimumAhead: 100, targetInventory: 100);

      for (int i = 0; i < coord.length; i++) {
        expect(coord.inventory[i].feedIndex, equals(i));
      }
    });

    test('persists inventory to store after fetch', () async {
      final repo = _FakeRepository(totalVideos: 200);
      final store = _FakeStore();
      final coord = FeedInventoryCoordinator(store: store, repository: repo);

      await coord.ensureRunway(
          currentIndex: 0, minimumAhead: 100, targetInventory: 100);

      final persisted = await store.readAll();
      expect(persisted.length, greaterThanOrEqualTo(100));
    });

    test('loads persisted inventory on cold start without network', () async {
      final repo = _FakeRepository(totalVideos: 0); // no network
      final store = _FakeStore();

      // Pre-populate store.
      final saved = List.generate(
        50,
        (i) => PreloadVideo(
          id: 'cached$i',
          feedIndex: i,
          thumbnailUrl: '',
          videoUrl: 'https://example.com/$i.mp4',
        ),
      );
      await store.replaceAll(saved);

      final coord = FeedInventoryCoordinator(store: store, repository: repo);
      // Ask for less than what is in the store — should not hit network.
      await coord.ensureRunway(
          currentIndex: 0, minimumAhead: 50, targetInventory: 50);

      expect(coord.length, equals(50));
    });

    test('clearSession empties inventory and store', () async {
      final repo = _FakeRepository(totalVideos: 200);
      final store = _FakeStore();
      final coord = FeedInventoryCoordinator(store: store, repository: repo);

      await coord.ensureRunway(
          currentIndex: 0, minimumAhead: 50, targetInventory: 50);
      expect(coord.length, greaterThan(0));

      await coord.clearSession();
      expect(coord.length, equals(0));
      expect(await store.count(), equals(0));
    });
  });

  // ── PreloadVideo URL resolution tests ──────────────────────────────────────

  group('PreloadVideo.resolvePlaybackUrl', () {
    const video = PreloadVideo(
      id: 'test',
      feedIndex: 0,
      thumbnailUrl: 'https://example.com/thumb.jpg',
      videoUrl: 'https://example.com/raw.mp4',
      previewUrl: 'https://example.com/preview.mp4',
      hlsLowUrl: 'https://example.com/low.m3u8',
      hlsStandardUrl: 'https://example.com/standard.m3u8',
      hlsHdUrl: 'https://example.com/hd.m3u8',
      hlsMasterUrl: 'https://example.com/master.m3u8',
    );

    test('previewOnly returns previewUrl first', () {
      expect(
        video.resolvePlaybackUrl(previewOnly: true),
        equals('https://example.com/preview.mp4'),
      );
    });

    test('preferHd returns hlsHdUrl first', () {
      expect(
        video.resolvePlaybackUrl(preferHd: true),
        equals('https://example.com/hd.m3u8'),
      );
    });

    test('default returns previewUrl first', () {
      expect(video.resolvePlaybackUrl(),
          equals('https://example.com/preview.mp4'));
    });

    test('falls back to videoUrl when no preview URLs present', () {
      const minimal = PreloadVideo(
        id: 'x',
        feedIndex: 0,
        thumbnailUrl: '',
        videoUrl: 'https://example.com/x.mp4',
      );
      expect(minimal.resolvePlaybackUrl(previewOnly: true),
          equals('https://example.com/x.mp4'));
    });

    test('preferHd falls back to hlsStandardUrl when no HD url', () {
      const noHd = PreloadVideo(
        id: 'y',
        feedIndex: 0,
        thumbnailUrl: '',
        videoUrl: 'https://example.com/y.mp4',
        hlsStandardUrl: 'https://example.com/standard.m3u8',
      );
      expect(noHd.resolvePlaybackUrl(preferHd: true),
          equals('https://example.com/standard.m3u8'));
    });
  });

  // ── FeedPage tests ──────────────────────────────────────────────────────────

  group('FeedPage', () {
    test('hasMore is false when cursor is null', () {
      const page = FeedPage(videos: [], nextCursor: null, hasMore: false);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('hasMore is true when nextCursor is present', () {
      final page = FeedPage(
        videos: [
          const PreloadVideo(
              id: 'v0', feedIndex: 0, thumbnailUrl: '', videoUrl: 'u'),
        ],
        nextCursor: 'cursor_abc',
        hasMore: true,
      );
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, equals('cursor_abc'));
    });
  });
}
