import '../context/floating_context.dart';

abstract class FloatingFramework {
  Future<void> start(
    FloatingContext context,
  );
  Future<void> stop();
  Future<void> restore();
}
