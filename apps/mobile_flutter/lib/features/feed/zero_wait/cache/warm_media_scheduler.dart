import 'dart:async';
import 'dart:collection';
import 'yohpal_video_cache.dart';

class _WarmJob {
  const _WarmJob({
    required this.videoId,
    required this.url,
    required this.priority,
  });
  final String videoId;
  final String url;
  final int priority;
}

/// Priority download queue for the warm disk-cache tier.
///
/// Supports concurrent downloads (up to [_concurrency]) and deduplicates
/// URLs that are already queued or active.
final class WarmMediaScheduler {
  WarmMediaScheduler({required YohPalVideoCache cache}) : _cache = cache;

  final YohPalVideoCache _cache;
  final Queue<_WarmJob> _queue = Queue();
  final Set<String> _queuedIds = {};
  final Set<String> _activeIds = {};

  int _concurrency = 2;
  bool _pumping = false;

  int get queuedCount => _queue.length;
  int get activeCount => _activeIds.length;

  void configureConcurrency(int concurrency) {
    _concurrency = concurrency.clamp(0, 8);
    unawaited(_pump());
  }

  void enqueue({
    required String videoId,
    required String url,
    required int priority,
  }) {
    if (url.isEmpty || _queuedIds.contains(videoId) || _activeIds.contains(videoId)) {
      return;
    }
    _queue.add(_WarmJob(videoId: videoId, url: url, priority: priority));
    _queuedIds.add(videoId);
    _sortQueue();
    unawaited(_pump());
  }

  /// Removes queued (not yet active) jobs whose videoId is not in [videoIds].
  void retainOnly(Set<String> videoIds) {
    final retained = _queue.where((j) => videoIds.contains(j.videoId)).toList();
    _queue
      ..clear()
      ..addAll(retained);
    _queuedIds
      ..clear()
      ..addAll(retained.map((j) => j.videoId));
  }

  void clearQueued() {
    _queue.clear();
    _queuedIds.clear();
  }

  Future<void> _pump() async {
    if (_pumping || _concurrency == 0) return;
    _pumping = true;
    try {
      while (_queue.isNotEmpty && _activeIds.length < _concurrency) {
        final job = _queue.removeFirst();
        _queuedIds.remove(job.videoId);
        _activeIds.add(job.videoId);
        unawaited(_download(job).whenComplete(() {
          _activeIds.remove(job.videoId);
          unawaited(_pump());
        }));
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _download(_WarmJob job) async {
    try {
      await _cache.download(job.url);
    } catch (_) {}
  }

  void _sortQueue() {
    final sorted = _queue.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    _queue
      ..clear()
      ..addAll(sorted);
  }
}
