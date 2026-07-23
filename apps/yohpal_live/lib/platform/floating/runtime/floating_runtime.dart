import '../context/floating_context.dart';

abstract class FloatingRuntime {
  Future<bool> isSupported();
  Future<bool> start(FloatingContext context);
  Future<void> stop();
  Future<void> restore();
}
