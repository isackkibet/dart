import 'dart:async';
import 'package:flutter/foundation.dart';
import '../zero_wait/controllers/feed_inventory_coordinator.dart';
import '../zero_wait/controllers/zero_wait_playback_controller.dart';
import '../zero_wait/models/preload_video.dart';
import '../zero_wait/policy/zero_wait_buffer_policy.dart';

final class VideoFeedController extends ChangeNotifier {
  VideoFeedController({
    required FeedInventoryCoordinator inventory,
    required ZeroWaitPlaybackController playback,
  })  : _inventory = inventory,
        _playback = playback;

  final FeedInventoryCoordinator _inventory;
  final ZeroWaitPlaybackController _playback;

  ZeroWaitBufferPolicy? _policy;
  int _currentIndex = 0;
  bool _replenishing = false;

  List<PreloadVideo> get inventory => _inventory.inventory;
  int get length => _inventory.length;
  PreloadVideo? videoAt(int index) => _inventory[index];

  /// Called once with the pre-warmed result from [FeedStartupWarmupService].
  Future<void> initialize({
    required List<PreloadVideo> initialVideos,
    required ZeroWaitBufferPolicy policy,
  }) async {
    _policy = policy;
    _playback.configure(policy);
    await _playback.setInventory(initialVideos);
    if (initialVideos.isNotEmpty) {
      await _playback.play(initialVideos.first.id);
    }
    notifyListeners();
  }

  Future<void> onPageChanged(int index) async {
    _currentIndex = index;
    unawaited(_playback.maintainRunway(currentIndex: index));

    final video = _inventory[index];
    if (video != null) {
      await _playback.play(video.id);
    }

    final remaining = _inventory.length - index - 1;
    final policy = _policy;
    if (policy != null && remaining <= policy.minimumRunway && !_replenishing) {
      unawaited(_replenish(policy));
    }

    notifyListeners();
  }

  Future<void> clearSession() async {
    await _inventory.clearSession();
    await _playback.clearSession();
    _policy = null;
    notifyListeners();
  }

  Future<void> _replenish(ZeroWaitBufferPolicy policy) async {
    if (_replenishing) return;
    _replenishing = true;
    try {
      final videos = await _inventory.ensureRunway(
        currentIndex: _currentIndex,
        minimumAhead: policy.minimumRunway,
        targetInventory: policy.targetInventory,
      );
      await _playback.setInventory(videos);
      notifyListeners();
    } finally {
      _replenishing = false;
    }
  }

}
