import '../context/floating_context.dart';
import '../actions/floating_action.dart';

abstract class FloatingModuleAdapter {
  String get moduleName;
  bool get supportsFloating;
  Future<List<FloatingAction>> resolveActions(FloatingContext context);
  Future<void> onFloatingStarted(FloatingContext context);
  Future<void> onFloatingStopped(FloatingContext context);
}
