import '../platform_provider.dart';

abstract class YohPalModuleMigrationAdapter {
  String get moduleName;

  Future<void> validateSharedIdentity(YohPalPlatformProvider platform);
  Future<void> validateSharedWallet(YohPalPlatformProvider platform);
  Future<void> validateSharedBrain(YohPalPlatformProvider platform);
  Future<void> validateSharedAnalytics(YohPalPlatformProvider platform);
  Future<void> validateSharedDeepLinks(YohPalPlatformProvider platform);
}
