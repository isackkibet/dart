import 'package:flutter/material.dart';
import '../features/ads/models/rewarded_ad_model.dart';
import '../features/ads/screens/rewarded_ad_watch_screen.dart';
import '../features/ads/screens/ads_earnings_leaderboard_screen.dart';
import '../features/video_upload/screens/upload_screen.dart';
import '../features/video_editor_ai/screens/ai_editor_screen.dart';
import '../features/live_streaming/screens/go_live_screen.dart';
import '../features/live_streaming/screens/live_discovery_screen.dart';
import '../features/live_streaming/screens/live_viewer_screen.dart';
import '../features/contacts_growth/screens/invite_contacts_screen.dart';
import '../features/affiliate/screens/affiliate_dashboard_screen.dart';
import '../features/monetisation/screens/creator_earnings_screen.dart';
import '../features/monetisation/screens/payout_history_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/wallet/screens/wallet_screen.dart';
import '../features/wallet_web/screens/wallet_status_screen.dart';
import '../features/subscriptions/screens/creator_subscription_screen.dart';
import '../features/ads/screens/advertiser_dashboard_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_room_screen.dart';
import '../features/creator_profile/screens/creator_profile_screen.dart';
import '../features/creator_profile/screens/edit_creator_profile_screen.dart';
import '../features/creator_profile/screens/creator_analytics_screen.dart';
import '../features/multistreaming/screens/multistream_setup_screen.dart';
import '../features/polls/screens/poll_detail_screen.dart';
import '../features/notifications/screens/notification_inbox_screen.dart';
import '../features/ycios/models/ycios_project_model.dart';
import '../features/ycios/screens/ycios_home_screen.dart';
import '../features/ycios/screens/ycios_project_detail_screen.dart';
// Phase 1A: Hub navigation — stub replacements
import '../features/rewards/screens/coupon_wallet_screen.dart';
import '../features/rewards/screens/ads_arena_screen.dart';
import '../features/community/screens/watch_later_screen.dart';
import '../features/community/screens/collaboration_screen.dart';
import '../features/gifts/screens/gift_creator_screen.dart';
import '../features/commerce/screens/timeline_overlay_screen.dart';
import '../features/settings/theme_settings_screen.dart';
import '../features/feed/debug/zero_wait_debug_screen.dart';

class YohPalRouter {
  // '/' is absent — app.dart sets home: AuthGate(child: YohPalMainShell())
  // Flutter throws if '/' appears in routes when home is also set.
  static Map<String, WidgetBuilder> routes = {
    SearchScreen.routeName: (_) => const SearchScreen(),
    ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
    UploadScreen.routeName: (_) => const UploadScreen(),

    // Live streaming
    GoLiveScreen.routeName: (_) => const GoLiveScreen(),
    LiveDiscoveryScreen.routeName: (_) => const LiveDiscoveryScreen(),
    LiveViewerScreen.routeName: (context) {
      final sessionId = ModalRoute.of(context)!.settings.arguments as String;
      return LiveViewerScreen(sessionId: sessionId);
    },
    MultistreamSetupScreen.routeName: (context) {
      final liveSessionId =
          ModalRoute.of(context)!.settings.arguments as String;
      return MultistreamSetupScreen(liveSessionId: liveSessionId);
    },

    // Chat
    ChatListScreen.routeName: (_) => const ChatListScreen(),
    ChatRoomScreen.routeName: (context) {
      final conversationId =
          ModalRoute.of(context)!.settings.arguments as String;
      return ChatRoomScreen(conversationId: conversationId);
    },

    // Creator tools
    AiEditorScreen.routeName: (context) {
      final videoId =
          ModalRoute.of(context)!.settings.arguments as String? ?? '';
      return AiEditorScreen(videoId: videoId);
    },
    '/creator-profile': (context) {
      final uid = ModalRoute.of(context)!.settings.arguments as String? ?? '';
      return CreatorProfileScreen(creatorUid: uid);
    },
    EditCreatorProfileScreen.routeName: (context) {
      final uid = ModalRoute.of(context)!.settings.arguments as String? ?? '';
      return EditCreatorProfileScreen(creatorUid: uid);
    },
    CreatorAnalyticsScreen.routeName: (context) {
      final uid = ModalRoute.of(context)!.settings.arguments as String? ?? '';
      return CreatorAnalyticsScreen(creatorUid: uid);
    },
    CreatorEarningsScreen.routeName: (_) => const CreatorEarningsScreen(),
    PayoutHistoryScreen.routeName: (_) => const PayoutHistoryScreen(),

    // Growth & monetisation
    '/invite': (_) => const InviteContactsScreen(),
    '/affiliate': (_) => const AffiliateDashboardScreen(),
    AdvertiserDashboardScreen.routeName: (_) =>
        const AdvertiserDashboardScreen(),

    // Wallet & subscriptions
    WalletScreen.routeName: (_) => const WalletScreen(),
    WalletStatusScreen.routeName: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as WalletStatusArgs;
      return WalletStatusScreen(args: args);
    },
    CreatorSubscriptionScreen.routeName: (context) {
      final creatorId = ModalRoute.of(context)!.settings.arguments as String;
      return CreatorSubscriptionScreen(creatorId: creatorId);
    },

    // Polls
    PollDetailScreen.routeName: (context) {
      final pollId = ModalRoute.of(context)!.settings.arguments as String;
      return PollDetailScreen(pollId: pollId);
    },

    // Notifications
    NotificationInboxScreen.routeName: (_) => const NotificationInboxScreen(),

    // Business profile placeholder
    '/business-profile': (context) {
      final businessId = ModalRoute.of(context)!.settings.arguments as String;
      return Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: Center(child: Text('Business: $businessId')),
      );
    },

    // ── YCIOS — AI Creator Intelligence OS ───────────────────────────────
    YciosHomeScreen.routeName: (_) => const YciosHomeScreen(),
    YciosProjectDetailScreen.routeName: (context) {
      final project =
          ModalRoute.of(context)!.settings.arguments as YciosProjectModel;
      return YciosProjectDetailScreen(project: project);
    },
    '/ycios-archived': (_) => const _StubScreen(title: 'Archived Projects'),

    // Phase 7D: Advanced Ads Monetisation
    RewardedAdWatchScreen.routeName: (context) {
      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return RewardedAdWatchScreen(
        ad: args['ad'] as RewardedAdModel,
        liveSessionId: args['liveSessionId'] as String?,
        creatorId: args['creatorId'] as String?,
      );
    },
    AdsEarningsLeaderboardScreen.routeName: (_) =>
        const AdsEarningsLeaderboardScreen(),

    // ── Phase 1A: Hub Navigation — stub replacements ──────────────────────
    CouponWalletScreen.routeName: (_) => const CouponWalletScreen(),
    AdsArenaScreen.routeName: (_) => const AdsArenaScreen(),
    WatchLaterScreen.routeName: (_) => const WatchLaterScreen(),
    CollaborationScreen.routeName: (_) => const CollaborationScreen(),
    GiftCreatorScreen.routeName: (context) {
      final creatorId =
          ModalRoute.of(context)!.settings.arguments as String? ?? '';
      return GiftCreatorScreen(creatorId: creatorId);
    },
    TimelineOverlayScreen.routeName: (_) => const TimelineOverlayScreen(),

    // ── Phase 10B: Unified Gold & Black Brand Theme ───────────────────────
    ThemeSettingsScreen.routeName: (_) => const ThemeSettingsScreen(),

    // ── Zero-Wait debug harness (internal) ───────────────────────────────
    '/zero-wait-debug': (_) => const ZeroWaitDebugScreen(),
  };
}

class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
