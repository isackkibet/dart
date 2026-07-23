import 'adapters/floating_module_adapter.dart';
import 'context/floating_context.dart';
import 'actions/floating_action.dart';
import 'runtime/floating_runtime.dart';

class FloatingPlatform {
  final FloatingRuntime runtime;
  final Map<String, FloatingModuleAdapter> _adapters = {};
  FloatingPlatform({
    required this.runtime,
  });
  void register(FloatingModuleAdapter adapter) {
    _adapters[adapter.moduleName] = adapter;
  }
  bool supports(String module) {
    return _adapters[module]?.supportsFloating == true;
  }
  Future<bool> start(FloatingContext context) async {
    final adapter = _adapters[context.module];
    if (adapter == null || !adapter.supportsFloating) {
      return false;
    }
    final started = await runtime.start(context);
    if (started) {
      await adapter.onFloatingStarted(context);
    }
    return started;
  }
  Future<List<FloatingAction>> actionsFor(FloatingContext context) async {
    final adapter = _adapters[context.module];
    if (adapter == null) return [];
    return adapter.resolveActions(context);
  }
  Future<void> stop(FloatingContext context) async {
    await runtime.stop();
    await _adapters[context.module]?.onFloatingStopped(context);
  }
}
