import 'contextual_pip_action.dart';

class ContextualPipResolver {
  List<ContextualPipAction> resolve({
    required String videoId,
    required String creatorId,
    String? jobId,
    String? hustleTaskId,
    String? productId,
    bool live = false,
  }) {
    return [
      ContextualPipAction(
        type: ContextualPipActionType.like,
        label: 'Like',
        deepLink: 'yohpal://live/video/$videoId?action=like',
      ),
      ContextualPipAction(
        type: ContextualPipActionType.follow,
        label: 'Follow',
        deepLink: 'yohpal://live/creator/$creatorId?action=follow',
      ),
      if (live)
        ContextualPipAction(
          type: ContextualPipActionType.chat,
          label: 'Chat',
          deepLink: 'yohpal://live/chat/$videoId',
        ),
      if (live)
        ContextualPipAction(
          type: ContextualPipActionType.gift,
          label: 'Gift',
          deepLink: 'yohpal://wallet/gift/$creatorId?source=live',
        ),
      ContextualPipAction(
        type: ContextualPipActionType.askAi,
        label: 'Ask AI',
        deepLink: 'yohpal://brain/ask?videoId=$videoId',
      ),
      if (jobId != null)
        ContextualPipAction(
          type: ContextualPipActionType.continueInJobs,
          label: 'Apply',
          deepLink: 'yohpal://jobs/job/$jobId',
        ),
      if (hustleTaskId != null)
        ContextualPipAction(
          type: ContextualPipActionType.continueInHustle,
          label: 'Do Task',
          deepLink: 'yohpal://hustle/task/$hustleTaskId',
        ),
      if (productId != null)
        ContextualPipAction(
          type: ContextualPipActionType.openMarketProduct,
          label: 'Shop',
          deepLink: 'yohpal://market/product/$productId',
        ),
    ];
  }
}
