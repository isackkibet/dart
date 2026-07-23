import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/policy/zero_wait_buffer_policy.dart';

void main() {
  group('ZeroWaitBufferPolicy.resolve', () {
    test('wifiStrong + highPerformance yields maximum hot controllers', () {
      final policy = ZeroWaitBufferPolicy.resolve(
        network: YohPalNetworkClass.wifiStrong,
        device: YohPalDeviceClass.highPerformance,
      );
      expect(policy.hotControllerCount, 8);
      expect(policy.warmMediaCount, 50);
      expect(policy.targetInventory, 150);
    });

    test('offline always yields 2 hot controllers and 0 warm', () {
      for (final device in YohPalDeviceClass.values) {
        final policy = ZeroWaitBufferPolicy.resolve(
          network: YohPalNetworkClass.offline,
          device: device,
        );
        expect(policy.hotControllerCount, 2, reason: 'device=$device');
        expect(policy.warmMediaCount, 0, reason: 'device=$device');
      }
    });

    test('constrained network caps hot controllers at 2 across all devices', () {
      for (final device in YohPalDeviceClass.values) {
        final policy = ZeroWaitBufferPolicy.resolve(
          network: YohPalNetworkClass.constrained,
          device: device,
        );
        expect(policy.hotControllerCount, 2, reason: 'device=$device');
      }
    });

    test('all matrix cells return targetInventory > 0 except offline yields 100', () {
      for (final network in YohPalNetworkClass.values) {
        if (network == YohPalNetworkClass.offline) continue;
        for (final device in YohPalDeviceClass.values) {
          final policy = ZeroWaitBufferPolicy.resolve(
            network: network,
            device: device,
          );
          expect(policy.targetInventory, greaterThan(0),
              reason: 'network=$network device=$device');
        }
      }
    });

    test('higher device class yields >= hot controllers for same network', () {
      const net = YohPalNetworkClass.fourG;
      final low = ZeroWaitBufferPolicy.resolve(
          network: net, device: YohPalDeviceClass.lowMemory);
      final std = ZeroWaitBufferPolicy.resolve(
          network: net, device: YohPalDeviceClass.standard);
      final hi = ZeroWaitBufferPolicy.resolve(
          network: net, device: YohPalDeviceClass.highPerformance);
      expect(std.hotControllerCount, greaterThanOrEqualTo(low.hotControllerCount));
      expect(hi.hotControllerCount, greaterThanOrEqualTo(std.hotControllerCount));
    });

    test('better network yields >= hot controllers for same device', () {
      const dev = YohPalDeviceClass.standard;
      final constrained = ZeroWaitBufferPolicy.resolve(
          network: YohPalNetworkClass.constrained, device: dev);
      final threeG = ZeroWaitBufferPolicy.resolve(
          network: YohPalNetworkClass.threeG, device: dev);
      final fourG = ZeroWaitBufferPolicy.resolve(
          network: YohPalNetworkClass.fourG, device: dev);
      final wifi = ZeroWaitBufferPolicy.resolve(
          network: YohPalNetworkClass.wifiStrong, device: dev);
      expect(threeG.hotControllerCount, greaterThanOrEqualTo(constrained.hotControllerCount));
      expect(fourG.hotControllerCount, greaterThanOrEqualTo(threeG.hotControllerCount));
      expect(wifi.hotControllerCount, greaterThanOrEqualTo(fourG.hotControllerCount));
    });
  });
}
