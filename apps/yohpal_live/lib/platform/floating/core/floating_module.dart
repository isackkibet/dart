abstract class FloatingModule {
  String get moduleName;
  bool get supportsFloating;
  Future<void> open();
  Future<void> minimize();
  Future<void> restore();
}
