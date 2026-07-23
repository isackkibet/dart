import '../controllers/feed_inventory_coordinator.dart';
import '../controllers/zero_wait_playback_controller.dart';
import '../models/preload_video.dart';
import '../policy/zero_wait_buffer_policy.dart';
import '../profiling/device_capability_profiler.dart';
import '../profiling/smart_network_profiler.dart';

final class FeedStartupWarmupResult {
  const FeedStartupWarmupResult({
    required this.inventory,
    required this.policy,
    required this.networkClass,
    required this.deviceClass,
  });

  final List<PreloadVideo> inventory;
  final ZeroWaitBufferPolicy policy;
  final YohPalNetworkClass networkClass;
  final YohPalDeviceClass deviceClass;
}

/// Runs all classification and inventory-warm tasks in parallel before the
/// feed screen mounts, so the first video plays without any network wait.
///
/// Call [execute] once at app startup and await the result before navigating
/// to [VideoFeedScreen].
final class FeedStartupWarmupService {
  FeedStartupWarmupService({
    required FeedInventoryCoordinator inventory,
    required ZeroWaitPlaybackController playback,
    required SmartNetworkProfiler networkProfiler,
    required DeviceCapabilityProfiler deviceProfiler,
  })  : _inventory = inventory,
        _playback = playback,
        _network = networkProfiler,
        _device = deviceProfiler;

  final FeedInventoryCoordinator _inventory;
  final ZeroWaitPlaybackController _playback;
  final SmartNetworkProfiler _network;
  final DeviceCapabilityProfiler _device;

  static const _targetInventory = 100;

  Future<FeedStartupWarmupResult> execute() async {
    // Classify network and device in parallel.
    final results = await Future.wait([
      _network.currentClass(),
      _device.classify(),
    ]);

    final networkClass = results[0] as YohPalNetworkClass;
    final deviceClass = results[1] as YohPalDeviceClass;

    final policy = ZeroWaitBufferPolicy.resolve(
      network: networkClass,
      device: deviceClass,
    );

    _playback.configure(policy);

    // Ensure at least [_targetInventory] videos are ready.
    final videos = await _inventory.ensureRunway(
      currentIndex: 0,
      minimumAhead: _targetInventory,
      targetInventory: _targetInventory,
    );

    if (videos.isNotEmpty) {
      await _playback.setInventory(videos);
      await _playback.play(videos.first.id);
    }

    return FeedStartupWarmupResult(
      inventory: videos,
      policy: policy,
      networkClass: networkClass,
      deviceClass: deviceClass,
    );
  }
}
