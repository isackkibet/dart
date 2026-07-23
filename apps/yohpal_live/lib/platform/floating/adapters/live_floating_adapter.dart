import 'floating_module_adapter.dart';
import '../context/floating_context.dart';
import '../actions/floating_action.dart';

class LiveFloatingAdapter implements FloatingModuleAdapter {
  @override
  String get moduleName => 'live';
  @override
  bool get supportsFloating => true;
  @override
  Future<List<FloatingAction>> resolveActions(FloatingContext context) async {
    final creatorId = context.payload['creatorId']?.toString();
    return [
      FloatingAction(
        type: FloatingActionType.like,
        label: 'Like',
        deepLink: 'yohpal://live/video/${context.entityId}?action=like',
      ),
      if (creatorId != null)
        FloatingAction(
          type: FloatingActionType.follow,
          label: 'Follow',
          deepLink: 'yohpal://live/creator/$creatorId?action=follow',
        ),
      if (context.isLive && creatorId != null)
        FloatingAction(
          type: FloatingActionType.gift,
          label: 'Gift',
          deepLink: 'yohpal://wallet/gift/$creatorId?source=live',
        ),
      FloatingAction(
        type: FloatingActionType.askAi,
        label: 'Ask AI',
        deepLink: 'yohpal://brain/ask?videoId=${context.entityId}',
      ),
    ];
  }
  @override
  Future<void> onFloatingStarted(FloatingContext context) async {}
  @override
  Future<void> onFloatingStopped(FloatingContext context) async {}
}
