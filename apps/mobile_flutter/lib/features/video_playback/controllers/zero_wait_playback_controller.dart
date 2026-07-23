import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../auth/session_cleanup_service.dart';
import '../services/adaptive_video_url_resolver.dart';
import '../services/smart_network_profiler.dart';
import '../services/video_media_cache.dart';

// Pairs a media_kit Player with the VideoController needed for rendering.
// VideoController lifetime is tied to the Player — disposing the Player
// also invalidates the VideoController, so we only call player.dispose().
class _MKBundle {
  _MKBundle({required this.player}) : videoController = VideoController(player);
  final Player player;
  final VideoController videoController;
  Future<void> dispose() => player.dispose();
}

/// Tiered zero-wait video buffer — 1.0H implementation (media_kit backend).
///
/// Uses libmpv via media_kit, giving software AVC/HEVC fallback on devices
/// with broken hardware decoders (e.g. Unisoc c2.unisoc.avc.decoder).
///
/// Tiers:
///   Active  — 1 Player currently playing.
///   Hot     — 2–8 fully buffered Players around current index.
///   Warm    — Next 5–50 preview/start URLs pre-downloaded to disk cache.
///   Ready   — Remaining feed records (provided by VideoFeedController).
final class ZeroWaitPlaybackController extends ChangeNotifier
    implements SessionScopedState {
  ZeroWaitPlaybackController({
    SmartNetworkProfiler? networkProfiler,
    AdaptiveVideoUrlResolver? urlResolver,
    VideoMediaCache? mediaCache,
  })  : _networkProfiler = networkProfiler ?? SmartNetworkProfiler(),
        _urlResolver = urlResolver ?? AdaptiveVideoUrlResolver(),
        _mediaCache = mediaCache ?? VideoMediaCache() {
    _initConnectivity();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  final SmartNetworkProfiler _networkProfiler;
  final AdaptiveVideoUrlResolver _urlResolver;
  final VideoMediaCache _mediaCache;

  final Map<String, _MKBundle> _controllers = {};
  final Map<String, Map<String, dynamic>> _videoData = {};
  final Map<String, Future<void>> _initFutures = {};
  final Set<String> _warmSubmittedIds = {};
  static const _warmSetMaxSize = 200;

  StreamSubscription<NetworkClass>? _networkSub;
  int _currentIndex = 0;
  bool _isOnWifi = false;

  int dynamicPreloadAhead = 1;
  int _hotControllerLimit = 2;
  int _warmMediaCount = 10;
  bool _muted = false;

  bool get isOnWifi => _isOnWifi;
  bool get isMuted => _muted;

  void toggleMute() {
    _muted = !_muted;
    for (final b in _controllers.values) {
      b.player.setVolume(_muted ? 0 : 100);
    }
    notifyListeners();
  }

  bool isPreloaded(String videoId) => _controllers.containsKey(videoId);

  /// Returns the [VideoController] for rendering. Non-null as soon as the
  /// Player has been opened; the video may still be buffering at that point.
  VideoController? controllerFor(String id) => _controllers[id]?.videoController;

  /// Returns the raw [Player] — used by the widget to attach stream listeners
  /// for first-frame detection and error handling.
  Player? playerFor(String id) => _controllers[id]?.player;

  // ── Connectivity ──────────────────────────────────────────────────────────

  Future<void> _initConnectivity() async {
    final nc = await _networkProfiler.currentClass();
    _applyNetworkClass(nc);
    _networkSub = _networkProfiler.watchClass().listen((nc) {
      final wasWifi = _isOnWifi;
      _applyNetworkClass(nc);
      if (_isOnWifi != wasWifi) {
        notifyListeners();
        unawaited(_onQualityChanged());
      }
    });
  }

  void _applyNetworkClass(NetworkClass nc) {
    _isOnWifi = nc == NetworkClass.wifi || nc == NetworkClass.fiveG;
    dynamicPreloadAhead = _networkProfiler.preloadAheadFor(nc);

    final cpus = Platform.numberOfProcessors;
    final deviceMax = cpus >= 8 ? 8 : cpus >= 6 ? 6 : 4;
    _hotControllerLimit = switch (nc) {
      NetworkClass.wifi || NetworkClass.fiveG => deviceMax,
      NetworkClass.fourG => deviceMax.clamp(4, 6),
      NetworkClass.threeG => deviceMax.clamp(3, 4),
      _ => 2,
    };

    _warmMediaCount = switch (nc) {
      NetworkClass.wifi => 50,
      NetworkClass.fiveG => 40,
      NetworkClass.fourG => 30,
      NetworkClass.threeG => 15,
      NetworkClass.constrained => 5,
      _ => 0,
    };
  }

  // ── Core preload logic ────────────────────────────────────────────────────

  Future<void> warmVideoAdaptive(Map<String, dynamic> videoData) async {
    final id = videoData['id']?.toString();
    if (id == null || id.isEmpty) return;
    _videoData[id] = videoData;
    final url = _urlResolver.resolve(videoData: videoData, preferHd: _isOnWifi);
    if (url.isEmpty) return;
    await _warmUrl(id, url);
  }

  Future<void> preloadAroundAdaptive({
    required int currentIndex,
    required Map<String, dynamic>? Function(int index) dataFor,
  }) async {
    _currentIndex = currentIndex;

    final hotIndices = <int>{currentIndex};
    if (currentIndex > 0) hotIndices.add(currentIndex - 1);
    for (int ahead = 1; hotIndices.length < _hotControllerLimit; ahead++) {
      hotIndices.add(currentIndex + ahead);
    }

    for (final i in hotIndices.where((i) => i >= 0)) {
      final data = dataFor(i);
      if (data != null) await warmVideoAdaptive(data);
    }

    if (_warmMediaCount > 0) {
      final warmStart = currentIndex + _hotControllerLimit;
      for (int i = warmStart; i < warmStart + _warmMediaCount; i++) {
        final data = dataFor(i);
        if (data == null) break;
        final id = data['id']?.toString();
        if (id == null || _warmSubmittedIds.contains(id)) continue;
        final url = _urlResolver.resolveStartUrl(data);
        if (url.isNotEmpty) {
          if (_warmSubmittedIds.length >= _warmSetMaxSize) {
            _warmSubmittedIds.clear();
          }
          _warmSubmittedIds.add(id);
          unawaited(_mediaCache.prefetch(url));
        }
      }
    }

    _disposeFarAway(
        currentIndex: currentIndex, keepDistance: _hotControllerLimit + 1);
  }

  // ── Memory pressure ────────────────────────────────────────────────────────

  Future<void> handleMemoryPressure() async {
    final playing = _controllers.entries
        .where((e) => e.value.player.state.playing)
        .map((e) => e.key)
        .toSet();

    String? nextId;
    for (final entry in _videoData.entries) {
      final idx = entry.value['_feedIndex'];
      if (idx is int && idx == _currentIndex + 1) {
        nextId = entry.key;
        break;
      }
    }

    final retain = {...playing, if (nextId != null) nextId};
    await _disposeControllersExcept(retain);
    notifyListeners();
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  Future<void> play(String id) async {
    final bundle = _controllers[id];
    if (bundle == null) return;
    for (final entry in _controllers.entries) {
      if (entry.key != id && entry.value.player.state.playing) {
        await entry.value.player.pause();
      }
    }
    await bundle.player.play();
    notifyListeners();
  }

  Future<void> pause(String id) async {
    await _controllers[id]?.player.pause();
  }

  Future<void> disposeVideo(String id) async {
    final bundle = _controllers.remove(id);
    _videoData.remove(id);
    await bundle?.dispose();
    notifyListeners();
  }

  // ── Network quality change ────────────────────────────────────────────────

  Future<void> _onQualityChanged() async {
    for (final entry in _videoData.entries) {
      final id = entry.key;
      if (_controllers[id]?.player.state.playing == true) continue;
      _initFutures.remove(id);
      final old = _controllers.remove(id);
      await old?.dispose();
      await warmVideoAdaptive(entry.value);
    }
  }

  // ── Legacy API ────────────────────────────────────────────────────────────

  Future<void> warmVideo({
    required String videoId,
    required String url,
    Map<String, String> httpHeaders = const {},
  }) async {
    await _warmUrl(videoId, url);
  }

  Future<void> preloadAround({
    required int currentIndex,
    required List<String> videoIds,
    required String Function(String videoId) urlFor,
    Map<String, String> httpHeaders = const {},
  }) async {
    for (int i = currentIndex - 1;
        i <= currentIndex + dynamicPreloadAhead;
        i++) {
      if (i >= 0 && i < videoIds.length) {
        final id = videoIds[i];
        await _warmUrl(id, urlFor(id));
      }
    }
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _warmUrl(String id, String url) async {
    if (url.isEmpty) return;
    if (_controllers.containsKey(id)) return;
    if (_initFutures.containsKey(id)) {
      await _initFutures[id];
      return;
    }

    final cachedFile = await _mediaCache.getCached(url);
    final future = _doInit(id, cachedFile != null ? 'file://${cachedFile.path}' : url);
    _initFutures[id] = future;
    await future;
    _initFutures.remove(id);
  }

  Future<void> _doInit(String id, String uri) async {
    try {
      final bundle = _MKBundle(player: Player());
      await bundle.player.open(Media(uri), play: false);
      await bundle.player.setPlaylistMode(PlaylistMode.loop);
      await bundle.player.setVolume(_muted ? 0 : 100);

      final previous = _controllers.remove(id);
      await previous?.dispose();
      _controllers[id] = bundle;
      notifyListeners();
    } catch (_) {
      // URL invalid or network unreachable — widget startup timer handles retry.
    }
  }

  void _disposeFarAway({required int currentIndex, required int keepDistance}) {
    final toDispose = _videoData.entries
        .where((e) {
          final idx = e.value['_feedIndex'];
          return idx is int && (idx - currentIndex).abs() > keepDistance;
        })
        .map((e) => e.key)
        .toList();
    for (final id in toDispose) {
      unawaited(disposeVideo(id));
    }
  }

  Future<void> _disposeControllersExcept(Set<String> retainIds) async {
    final toDispose = _controllers.keys
        .where((id) => !retainIds.contains(id))
        .toList();
    for (final id in toDispose) {
      final bundle = _controllers.remove(id);
      await bundle?.dispose();
    }
  }

  // ── Session / lifecycle ───────────────────────────────────────────────────

  @override
  Future<void> clearSession() async {
    _initFutures.clear();
    _warmSubmittedIds.clear();
    for (final b in _controllers.values) {
      await b.dispose();
    }
    _controllers.clear();
    _videoData.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _networkSub?.cancel();
    _initFutures.clear();
    for (final b in _controllers.values) {
      b.player.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  late final _lifecycleObserver = _FeedLifecycleObserver(this);
}

class _FeedLifecycleObserver with WidgetsBindingObserver {
  _FeedLifecycleObserver(this._controller);
  final ZeroWaitPlaybackController _controller;

  @override
  void didHaveMemoryPressure() {
    unawaited(_controller.handleMemoryPressure());
  }
}
