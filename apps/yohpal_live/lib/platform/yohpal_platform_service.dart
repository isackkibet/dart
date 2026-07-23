abstract class YohPalPlatformService {
  Future<void> initialize();
  Future<void> login();
  Future<void> logout();
  Future<void> refreshSession();
}
