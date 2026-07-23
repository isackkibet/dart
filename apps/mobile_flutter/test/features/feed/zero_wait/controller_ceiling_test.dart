import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/feed/zero_wait/policy/zero_wait_buffer_policy.dart';

void main() {
  group('BufferPolicy hot-controller ceiling contracts', () {
    test('no policy ever exceeds 8 hot controllers', () {
      for (final net in YohPalNetworkClass.values) {
        for (final dev in YohPalDeviceClass.values) {
          final policy = ZeroWaitBufferPolicy.resolve(network: net, device: dev);
          expect(
            policy.hotControllerCount,
            lessThanOrEqualTo(8),
            reason: 'net=$net dev=$dev',
          );
        }
      }
    });

    test('no policy allows 0 hot controllers', () {
      for (final net in YohPalNetworkClass.values) {
        for (final dev in YohPalDeviceClass.values) {
          final policy = ZeroWaitBufferPolicy.resolve(network: net, device: dev);
          expect(
            policy.hotControllerCount,
            greaterThanOrEqualTo(1),
            reason: 'net=$net dev=$dev',
          );
        }
      }
    });

    test('offline network yields exactly 2 hot controllers and 0 warm', () {
      for (final dev in YohPalDeviceClass.values) {
        final policy = ZeroWaitBufferPolicy.resolve(
          network: YohPalNetworkClass.offline,
          device: dev,
        );
        expect(policy.hotControllerCount, 2, reason: 'dev=$dev');
        expect(policy.warmMediaCount, 0, reason: 'dev=$dev');
      }
    });

    test('wifiStrong + highPerformance is the global maximum', () {
      final maxPolicy = ZeroWaitBufferPolicy.resolve(
        network: YohPalNetworkClass.wifiStrong,
        device: YohPalDeviceClass.highPerformance,
      );
      for (final net in YohPalNetworkClass.values) {
        for (final dev in YohPalDeviceClass.values) {
          final p = ZeroWaitBufferPolicy.resolve(network: net, device: dev);
          expect(
            p.hotControllerCount,
            lessThanOrEqualTo(maxPolicy.hotControllerCount),
            reason: 'net=$net dev=$dev',
          );
        }
      }
    });
  });
}
