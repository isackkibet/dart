import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import '../cache/warm_media_scheduler.dart';
import '../cache/yohpal_video_cache.dart';
import '../models/preload_video.dart';
import '../policy/zero_wait_buffer_policy.dart';
import '../telemetry/zero_wait_telemetry.dart';

/// Tiered zero-wait playback controller.
///
/// Tiers:
///   Active — 1 VideoPlayerController currently playing.
///   Hot    — policy.hotControllerCount initialized controllers around current index.
///   Warm   — policy.warmMediaCount preview URLs pre-downloaded to disk.
final class ZeroWaitPlaybackController extends ChangeNotifier {
  ZeroWaitPlaybackController({
    required YohPalVideoCache cache,
    required WarmMediaScheduler scheduler,
    required ZeroWaitTelemetry telemetry,
  })  : _cache = cache,
        _scheduler = scheduler,
        _telemetry = telemetry;

  final YohPalVideoCache _cache;
  final WarmMediaScheduler _scheduler;
  final ZeroWaitTelemetry _telemetry;

  List<PreloadVideo> _inventory = [];
  final Map<String, PreloadVideo> _inventoryById = {};
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, Future<void>> _initializationFutures = {};
  final Set<String> _warmSubmitted = {};
  final Set<String> _failedIds = {};

  ZeroWaitBufferPolicy _policy = ZeroWaitBufferPolicy.resolve(
    network: YohPalNetworkClass.fourG,
    device: YohPalDeviceClass.standard,
  );

  bool _muted = false;
  String? _activeVideoId;
  int _currentIndex = 0;

  bool get isMuted => _muted;
  int get controllerCount => _controllers.length;
  int get inventoryCount => _inventory.length;

  VideoPlayerController? controllerFor(String videoId) => _controllers[videoId];
  bool isReady(String id) => _controllers[id]?.value.isInitialized ?? false;
  bool hasFailed(String id) => _failedIds.contains(id);

  void configure(ZeroWaitBufferPolicy policy) {
    _policy = policy;
    _scheduler.configureConcurrency(policy.concurrentDownloads);
  }

  void toggleMute() {
    _muted = !_muted;
    for (final c in _controllers.values) {
      c.setVolume(_muted ? 0 : 1);
    }
    notifyListeners();
  }

  /// Stores [videos] as the live inventory and pre-warms hot controllers.
  Future<void> setInventory(List<PreloadVideo> videos) async {
    _inventory = List.of(videos);
    _inventoryById
      ..clear()
      ..addAll({for (final v in videos) v.id: v});

    final hot = _window(0, _policy.hotControllerCount);
    for (final v in hot) {
      if (!_failedIds.contains(v.id)) unawaited(_initialize(v));
    }

    await _telemetry.event(ZeroWaitTelemetry.inventoryReady, {
      'inventory_size': videos.length,
    });
    notifyListeners();
  }

  /// Maintains all tiers around [currentIndex].
  Future<void> maintainRunway({required int currentIndex}) async {
    _currentIndex = currentIndex;

    final hot = _window(currentIndex, _policy.hotControllerCount);
    final hotIds = <String>{};
    for (final v in hot) {
      hotIds.add(v.id);
      if (!_failedIds.contains(v.id)) unawaited(_initialize(v));
    }

    final warmStart = (currentIndex + _policy.hotControllerCount)
        .clamp(0, _inventory.length);
    final warmEnd = (warmStart + _policy.warmMediaCount)
        .clamp(0, _inventory.length);
    final warmIds = <String>{};
    for (int i = warmStart; i < warmEnd; i++) {
      final v = _inventory[i];
      if (_failedIds.contains(v.id)) continue;
      warmIds.add(v.id);
      if (!_warmSubmitted.contains(v.id)) {
        _warmSubmitted.add(v.id);
        final url = v.resolvePlaybackUrl(previewOnly: true);
        if (url.isNotEmpty) {
          _scheduler.enqueue(
            videoId: v.id,
            url: url,
            priority: i - warmStart,
          );
        }
      }
    }

    // Evict controllers too far from the current position.
    final keepDistance = _policy.hotControllerCount + 1;
    final toEvict = _controllers.keys.where((id) {
      final v = _inventoryById[id];
      return v == null || (v.feedIndex - currentIndex).abs() > keepDistance;
    }).toList();
    for (final id in toEvict) {
      _controllers.remove(id)?.dispose();
    }

    _scheduler.retainOnly({...hotIds, ...warmIds});

    await _telemetry.event(ZeroWaitTelemetry.hotControllerReady, {
      'active_controllers': _controllers.length,
      'current_index': currentIndex,
    });

    notifyListeners();
  }

  Future<void> play(String videoId) async {
    // Pause any other playing controller.
    for (final entry in _controllers.entries) {
      if (entry.key != videoId && entry.value.value.isPlaying) {
        await entry.value.pause();
      }
    }
    _activeVideoId = videoId;

    var controller = _controllers[videoId];
    if (controller == null || !controller.value.isInitialized) {
      final video = _inventoryById[videoId];
      if (video != null && !_failedIds.contains(videoId)) {
        await _initialize(video);
        controller = _controllers[videoId];
      }
    }

    if (controller?.value.isInitialized == true) {
      await controller!.play();
    }
    notifyListeners();
  }

  Future<void> pause(String videoId) async {
    await _controllers[videoId]?.pause();
  }

  Future<void> handleMemoryPressure() async {
    final playing = _activeVideoId;
    final nextVideo = _currentIndex + 1 < _inventory.length
        ? _inventory[_currentIndex + 1]
        : null;

    final retained = <String>{
      if (playing != null) playing,
      if (nextVideo != null) nextVideo.id,
    };

    for (final id in _controllers.keys
        .where((id) => !retained.contains(id))
        .toList()) {
      await _controllers.remove(id)?.dispose();
    }
    _scheduler.clearQueued();
    notifyListeners();
    await _telemetry.event(ZeroWaitTelemetry.memoryPressure, {});
  }

  Future<void> clearSession() async {
    _inventory = [];
    _inventoryById.clear();
    _warmSubmitted.clear();
    _failedIds.clear();
    _scheduler.clearQueued();
    await _disposeAll();
    notifyListeners();
  }

  Future<void> _initialize(PreloadVideo video) async {
    final id = video.id;
    if (_failedIds.contains(id) || _controllers.containsKey(id)) return;
    if (_initializationFutures.containsKey(id)) {
      await _initializationFutures[id];
      return;
    }

    final future = _createController(video);
    _initializationFutures[id] = future;
    try {
      await future;
    } finally {
      _initializationFutures.remove(id);
    }
  }

  Future<void> _createController(PreloadVideo video) async {
    final url = video.resolvePlaybackUrl(
      preferHd: _policy.preferHd,
      previewOnly: _policy.previewOnly,
    );
    if (url.isEmpty) return;

    final cachedFile = await _cache.find(url);
    final ctrl = cachedFile != null
        ? VideoPlayerController.file(cachedFile)
        : VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await ctrl.initialize().timeout(const Duration(seconds: 5));
      // ExoPlayer/AVPlayer can complete initialize() without throwing even for
      // 403/404 — check value.hasError explicitly.
      if (ctrl.value.hasError) {
        throw Exception(ctrl.value.errorDescription ?? 'playback init error');
      }
      await ctrl.setLooping(true);
      await ctrl.setVolume(_muted ? 0 : 1);
      final old = _controllers.remove(video.id);
      await old?.dispose();
      _controllers[video.id] = ctrl;

      await _telemetry.event(
        cachedFile != null ? ZeroWaitTelemetry.cacheHit : ZeroWaitTelemetry.cacheMiss,
        {'video_id': video.id},
      );
      notifyListeners();
    } catch (e, st) {
      _failedIds.add(video.id);
      await ctrl.dispose();
      unawaited(
        _telemetry.error(e, st, reason: 'initialize ${video.id}'),
      );
      notifyListeners();
    }
  }

  Iterable<PreloadVideo> _window(int current, int count) {
    final start = (current - 1).clamp(0, _inventory.length);
    final end = (current + count).clamp(0, _inventory.length);
    return _inventory.sublist(start, end);
  }

  Future<void> _disposeAll() async {
    for (final c in _controllers.values) {
      await c.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _scheduler.clearQueued();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
}
