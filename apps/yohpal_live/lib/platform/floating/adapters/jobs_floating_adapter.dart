import 'floating_module_adapter.dart';
import '../context/floating_context.dart';
import '../actions/floating_action.dart';

class JobsFloatingAdapter implements FloatingModuleAdapter {
  @override
  String get moduleName => 'jobs';
  @override
  bool get supportsFloating => true;
  @override
  Future<List<FloatingAction>> resolveActions(FloatingContext context) async {
    return [
      FloatingAction(
        type: FloatingActionType.applyJob,
        label: 'Apply',
        deepLink: 'yohpal://jobs/job/${context.entityId}',
      ),
      FloatingAction(
        type: FloatingActionType.askAi,
        label: 'Ask AI',
        deepLink: 'yohpal://brain/ask?module=jobs&id=${context.entityId}',
      ),
    ];
  }
  @override
  Future<void> onFloatingStarted(FloatingContext context) async {}
  @override
  Future<void> onFloatingStopped(FloatingContext context) async {}
}
