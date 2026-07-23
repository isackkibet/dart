import 'dart:io';
import '../policy/zero_wait_buffer_policy.dart';

/// Classifies device capability into [YohPalDeviceClass].
///
/// iOS/Android do not expose physical RAM to Dart, so CPU core count is the
/// best available proxy: 2–3 → lowMemory, 4–7 → standard, 8+ → highPerformance.
abstract interface class DeviceCapabilityProfiler {
  Future<YohPalDeviceClass> classify();
}

final class DefaultDeviceCapabilityProfiler implements DeviceCapabilityProfiler {
  const DefaultDeviceCapabilityProfiler();

  @override
  Future<YohPalDeviceClass> classify() async {
    final cpus = Platform.numberOfProcessors;
    if (cpus >= 8) return YohPalDeviceClass.highPerformance;
    if (cpus >= 4) return YohPalDeviceClass.standard;
    return YohPalDeviceClass.lowMemory;
  }
}
