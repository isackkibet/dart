import '../data/zero_wait_feed_repository.dart';
import '../models/preload_video.dart';
import '../storage/feed_inventory_store.dart';

/// Manages the 100-video ready-tier inventory.
///
/// Responsibilities:
///  - Loads persisted inventory from [FeedInventoryStore] on first call.
///  - Fetches more pages from [ZeroWaitFeedRepository] when the runway ahead
///    of [currentIndex] falls below [minimumAhead].
///  - Deduplicates incoming records and reassigns contiguous [feedIndex] values.
///  - Persists the merged inventory back to [FeedInventoryStore].
final class FeedInventoryCoordinator {
  FeedInventoryCoordinator({
    required FeedInventoryStore store,
    required ZeroWaitFeedRepository repository,
  })  : _store = store,
        _repository = repository;

  final FeedInventoryStore _store;
  final ZeroWaitFeedRepository _repository;

  List<PreloadVideo> _inventory = [];
  String? _cursor;
  bool _fetching = false;

  List<PreloadVideo> get inventory => List.unmodifiable(_inventory);
  int get length => _inventory.length;

  PreloadVideo? operator [](int index) =>
      index >= 0 && index < _inventory.length ? _inventory[index] : null;

  /// Ensures at least [minimumAhead] videos remain beyond [currentIndex]
  /// and at least [targetInventory] total videos in inventory.
  ///
  /// Loads from the store on the first call, then fetches pages from
  /// [ZeroWaitFeedRepository] as needed. Returns the full inventory list.
  Future<List<PreloadVideo>> ensureRunway({
    required int currentIndex,
    required int minimumAhead,
    required int targetInventory,
  }) async {
    // Load from store on first call.
    if (_inventory.isEmpty) {
      _inventory = await _store.readAll();
    }

    final aheadCount = _inventory.length - currentIndex;
    if (aheadCount >= minimumAhead && _inventory.length >= targetInventory) {
      return _inventory;
    }

    if (_fetching) return _inventory;
    _fetching = true;
    try {
      while (_inventory.length < targetInventory) {
        final page = await _repository.fetchPage(
          limit: 50,
          cursor: _cursor,
        );
        if (page.videos.isEmpty) break;
        _mergeAndIndex(page.videos);
        _cursor = page.nextCursor;
        if (!page.hasMore) break;
      }
      await _store.replaceAll(_inventory);
    } finally {
      _fetching = false;
    }

    return _inventory;
  }

  Future<void> clearSession() async {
    _inventory = [];
    _cursor = null;
    await _store.clear();
  }

  void _mergeAndIndex(List<PreloadVideo> incoming) {
    final existingIds = {for (final v in _inventory) v.id};
    for (final v in incoming) {
      if (!existingIds.contains(v.id)) _inventory.add(v);
    }
    // Reassign contiguous feed indices after merge.
    _inventory = [
      for (int i = 0; i < _inventory.length; i++)
        _inventory[i].copyWith(feedIndex: i),
    ];
  }
}
