enum DeviceMemoryClass { low, medium, high }

class AdaptiveMemoryManager {
  DeviceMemoryClass classify({required int estimatedRamGb}) {
    if (estimatedRamGb <= 3) return DeviceMemoryClass.low;
    if (estimatedRamGb <= 6) return DeviceMemoryClass.medium;
    return DeviceMemoryClass.high;
  }

  int maxPredictivePreloads(DeviceMemoryClass memoryClass) {
    switch (memoryClass) {
      case DeviceMemoryClass.low:
        return 2;
      case DeviceMemoryClass.medium:
        return 4;
      case DeviceMemoryClass.high:
        return 8;
    }
  }
}
