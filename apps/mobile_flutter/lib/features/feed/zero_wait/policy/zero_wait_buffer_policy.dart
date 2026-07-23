enum YohPalNetworkClass {
  wifiStrong,
  wifiWeak,
  fiveG,
  fourG,
  threeG,
  constrained,
  offline,
}

enum YohPalDeviceClass {
  lowMemory,
  standard,
  highPerformance,
}

final class ZeroWaitBufferPolicy {
  const ZeroWaitBufferPolicy({
    required this.minimumRunway,
    required this.targetInventory,
    required this.hotControllerCount,
    required this.warmMediaCount,
    required this.concurrentDownloads,
    required this.preferHd,
    required this.previewOnly,
  });

  final int minimumRunway;
  final int targetInventory;

  /// Fully initialized VideoPlayerControllers to keep live.
  final int hotControllerCount;

  /// Videos whose preview/first segments are pre-downloaded to disk.
  final int warmMediaCount;

  final int concurrentDownloads;
  final bool preferHd;
  final bool previewOnly;

  static ZeroWaitBufferPolicy resolve({
    required YohPalNetworkClass network,
    required YohPalDeviceClass device,
  }) {
    final deviceHot = switch (device) {
      YohPalDeviceClass.lowMemory       => 4,
      YohPalDeviceClass.standard        => 6,
      YohPalDeviceClass.highPerformance => 8,
    };

    return switch (network) {
      YohPalNetworkClass.wifiStrong => ZeroWaitBufferPolicy(
          minimumRunway:     100,
          targetInventory:   150,
          hotControllerCount: deviceHot,
          warmMediaCount: device == YohPalDeviceClass.lowMemory ? 25 : 50,
          concurrentDownloads: device == YohPalDeviceClass.lowMemory ? 2 : 4,
          preferHd:    true,
          previewOnly: false,
        ),
      YohPalNetworkClass.wifiWeak => ZeroWaitBufferPolicy(
          minimumRunway:     100,
          targetInventory:   130,
          hotControllerCount: deviceHot.clamp(4, 6),
          warmMediaCount: device == YohPalDeviceClass.lowMemory ? 20 : 35,
          concurrentDownloads: 2,
          preferHd:    false,
          previewOnly: false,
        ),
      YohPalNetworkClass.fiveG => ZeroWaitBufferPolicy(
          minimumRunway:     100,
          targetInventory:   150,
          hotControllerCount: deviceHot,
          warmMediaCount: device == YohPalDeviceClass.lowMemory ? 20 : 40,
          concurrentDownloads: 3,
          preferHd:    true,
          previewOnly: false,
        ),
      YohPalNetworkClass.fourG => ZeroWaitBufferPolicy(
          minimumRunway:     100,
          targetInventory:   120,
          hotControllerCount: deviceHot.clamp(4, 6),
          warmMediaCount:    30,
          concurrentDownloads: 2,
          preferHd:    false,
          previewOnly: false,
        ),
      YohPalNetworkClass.threeG => ZeroWaitBufferPolicy(
          minimumRunway:     100,
          targetInventory:   110,
          hotControllerCount: deviceHot.clamp(3, 4),
          warmMediaCount:    15,
          concurrentDownloads: 1,
          preferHd:    false,
          previewOnly: true,
        ),
      YohPalNetworkClass.constrained => ZeroWaitBufferPolicy(
          minimumRunway:     100,
          targetInventory:   100,
          hotControllerCount: 2,
          warmMediaCount:    5,
          concurrentDownloads: 1,
          preferHd:    false,
          previewOnly: true,
        ),
      YohPalNetworkClass.offline => const ZeroWaitBufferPolicy(
          minimumRunway:     100,
          targetInventory:   100,
          hotControllerCount: 2,
          warmMediaCount:    0,
          concurrentDownloads: 0,
          preferHd:    false,
          previewOnly: true,
        ),
    };
  }

  @override
  String toString() =>
      'ZeroWaitBufferPolicy(hot=$hotControllerCount, warm=$warmMediaCount, '
      'runway=$minimumRunway–$targetInventory, hd=$preferHd, preview=$previewOnly)';
}

// Backward-compatible alias.
typedef BufferPolicy = ZeroWaitBufferPolicy;
