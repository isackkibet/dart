import '../models/context_action_model.dart';
import '../models/context_snapshot_model.dart';

class ContextIntelligenceEngine {
  List<ContextActionModel> evaluate(ContextSnapshotModel snapshot) {
    final actions = <ContextActionModel>[];

    if (snapshot.currentScreen == 'feed' && snapshot.videoId != null) {
      actions.add(ContextActionModel(
        id: 'ask_ai_${snapshot.videoId}',
        title: 'Ask AI',
        subtitle: 'Ask YohPal Brain about this video',
        type: 'ai_video_companion',
        route: '/ai-video-companion',
        priority: 0.95,
        arguments: {'videoId': snapshot.videoId},
      ));

      if (snapshot.hasCommerceTags) {
        actions.add(ContextActionModel(
          id: 'shop_${snapshot.videoId}',
          title: 'Shop this video',
          subtitle: 'View products linked to this content',
          type: 'commerce',
          route: '/timeline-overlay-detail',
          priority: 0.88,
          arguments: {'videoId': snapshot.videoId},
        ));
      }

      if (snapshot.hasActiveCoupon) {
        actions.add(ContextActionModel(
          id: 'coupon_${snapshot.videoId}',
          title: 'Claim coupon',
          subtitle: 'Unlock savings from this content',
          type: 'coupon',
          route: '/coupon-wallet',
          priority: 0.82,
          arguments: {'videoId': snapshot.videoId},
        ));
      }

      if (snapshot.hasPoll) {
        actions.add(ContextActionModel(
          id: 'poll_${snapshot.videoId}',
          title: 'Vote now',
          subtitle: 'Join the video poll',
          type: 'poll',
          route: '/poll-detail',
          priority: 0.78,
          arguments: {'videoId': snapshot.videoId},
        ));
      }
    }

    if (snapshot.creatorId != null && snapshot.canMessageCreator) {
      actions.add(ContextActionModel(
        id: 'chat_${snapshot.creatorId}',
        title: 'Chat with creator',
        subtitle: 'Start a direct conversation',
        type: 'chat',
        route: '/messages',
        priority: 0.76,
        arguments: {'creatorId': snapshot.creatorId},
      ));
    }

    if (snapshot.creatorId != null && snapshot.isLiveAvailable) {
      actions.add(ContextActionModel(
        id: 'live_${snapshot.creatorId}',
        title: 'Join creator live',
        subtitle: 'Watch live now',
        type: 'live',
        route: '/live-discovery',
        priority: 0.86,
        arguments: {'creatorId': snapshot.creatorId},
      ));
    }

    actions.add(const ContextActionModel(
      id: 'earn_ads',
      title: 'Earn from Ads Arena',
      subtitle: 'Watch rewarded ads and unlock coupons',
      type: 'rewarded_ads',
      route: '/ads-arena',
      priority: 0.52,
    ));

    actions.sort((a, b) => b.priority.compareTo(a.priority));
    return actions.take(5).toList();
  }
}
