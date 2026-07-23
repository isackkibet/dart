import 'package:yohpal_live_streaming/yohpal_live_streaming.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/theme/yohpal_theme_controller.dart';
import '../design_system/theme/yohpal_theme.dart';
import '../features/video_feed/startup/feed_startup_warmup_service.dart';
import 'yohpal_bootstrap.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/auth/repositories/auth_repository.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/session_cleanup_service.dart';
import '../features/auth/widgets/auth_gate.dart';
import '../features/comments/controllers/comments_controller.dart';
import '../features/comments/repositories/comment_repository.dart';
import '../features/creator_profile/controllers/creator_profile_controller.dart';
import '../features/creator_profile/repositories/creator_profile_repository.dart';
import '../features/creator_profile/repositories/follow_repository.dart';
import '../features/notifications/controllers/notification_controller.dart';
import '../features/notifications/services/notification_service.dart';
import '../features/video_editor_ai/controllers/ai_editor_controller.dart';
import '../features/video_editor_ai/repositories/ai_publish_repository.dart';
import '../features/video_editor_ai/repositories/ai_video_repository.dart';
import '../features/video_editor_ai/services/ai_caption_service.dart';
import '../features/video_editor_ai/services/ai_creator_api_service.dart';
import '../features/video_editor_ai/services/ai_hashtag_service.dart';
import '../features/video_editor_ai/services/ai_hook_service.dart';
import '../features/video_editor_ai/services/ai_thumbnail_service.dart';
import '../features/video_editor_ai/services/ai_trim_service.dart';
import '../features/video_editor_ai/services/ai_viral_score_service.dart';
import '../features/video_feed/controllers/video_feed_controller.dart';
import '../features/video_feed/controllers/video_interaction_controller.dart';
import '../features/video_feed/repositories/video_feed_repository.dart';
import '../features/navigation/yohpal_main_shell.dart';
import '../features/video_feed/services/video_interaction_service.dart';
import '../features/live_streaming/controllers/live_stream_controller.dart';
import '../features/live_streaming/repositories/live_chat_repository.dart';
import '../features/live_streaming/repositories/live_gift_repository.dart';
import '../features/live_streaming/repositories/live_repository.dart';
import '../features/live_streaming/services/gift_service.dart';
import '../features/live_streaming/services/live_token_service.dart';
import '../features/multistreaming/controllers/multistream_controller.dart';
import '../features/multistreaming/repositories/multistream_repository.dart';
import '../features/multistreaming/services/multistream_service.dart';
import '../features/live_streaming/controllers/live_commerce_controller.dart';
import '../features/live_streaming/repositories/live_commerce_repository.dart';
import '../features/contacts_growth/services/contact_import_service.dart';
import '../features/contacts_growth/services/ai_invite_ranker.dart';
import '../features/contacts_growth/repositories/contacts_repository.dart';
import '../features/contacts_growth/controllers/contacts_controller.dart';
import '../features/affiliate/repositories/affiliate_repository.dart';
import '../features/affiliate/services/affiliate_service.dart';
import '../features/affiliate/controllers/affiliate_controller.dart';
import '../features/video_upload/controllers/video_upload_controller.dart';
import '../features/video_upload/repositories/video_upload_repository.dart';
import '../features/video_upload/services/video_storage_service.dart';
import '../features/monetisation/repositories/creator_earnings_repository.dart';
import '../features/monetisation/services/monetisation_service.dart';
import '../features/monetisation/controllers/creator_earnings_controller.dart';
import '../features/ads/repositories/ads_repository.dart';
import '../features/ads/services/ad_delivery_service.dart';
import '../features/ads/controllers/ads_controller.dart';
import '../features/ads/repositories/rewarded_ads_repository.dart';
import '../features/ads/controllers/rewarded_ads_controller.dart';
import '../features/wallet/repositories/wallet_repository.dart';
import '../features/wallet/services/wallet_service.dart';
import '../features/wallet/controllers/wallet_controller.dart';
import '../features/subscriptions/repositories/subscription_repository.dart';
import '../features/chat/repositories/chat_repository.dart';
import '../features/chat/controllers/chat_controller.dart';
import '../features/search/repositories/search_repository.dart';
import '../features/search/services/search_service.dart';
import '../features/search/controllers/search_controller.dart';
import '../features/polls/repositories/poll_repository.dart';
import '../features/polls/controllers/poll_controller.dart';
import '../features/notifications/repositories/notification_inbox_repository.dart';
import '../features/notifications/controllers/notification_inbox_controller.dart';
import '../features/engagement/repositories/private_engagement_repository.dart';
import '../features/engagement/controllers/video_engagement_rail_controller.dart';
import '../features/feed/data/engagement_repository.dart';
import '../features/feed/data/firestore_engagement_repository.dart';
import '../features/ycios/repositories/ycios_repository.dart';
import '../features/ycios/controllers/ycios_controller.dart';
import '../features/video_playback/controllers/zero_wait_playback_controller.dart';
import '../features/video_playback/repositories/playback_diagnostics_repository.dart';
import '../features/predictive/controllers/predictive_experience_controller.dart';
import '../features/predictive/repositories/app_performance_repository.dart';
import '../features/predictive/services/adaptive_memory_manager.dart';
import '../features/predictive/services/predictive_asset_cache.dart';
import '../features/predictive/services/predictive_navigation_engine.dart';
import '../features/context_intelligence/controllers/context_intelligence_controller.dart';
import '../features/context_intelligence/repositories/context_analytics_repository.dart';
import '../features/context_intelligence/services/context_action_engine.dart';
import '../features/context_intelligence/services/context_intelligence_engine.dart';
import '../core/config/yohpal_environment.dart';
import '../core/observability/yohpal_crash_reporter.dart';
import '../core/routes/unknown_route_screen.dart';
import '../core/web_handoff/yohpal_web_handoff.dart';
import 'router.dart';

final _yohPalEnvironment = YohPalEnvironment.fromDefines();

/// Single navigator key — shared with NotificationController for tap routing.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class YohPalLiveApp extends StatelessWidget {
  const YohPalLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Brand Theme (Phase 10B) ────────────────────────────────────────
        ChangeNotifierProvider<YohPalThemeController>(
          create: (_) => YohPalThemeController(),
        ),

        // ── Observability ─────────────────────────────────────────────────
        Provider<YohPalCrashReporter>(
          create: (_) => FirebaseYohPalCrashReporter(),
        ),

        // ── Auth ──────────────────────────────────────────────────────────
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (ctx) => AuthController(
            repository: ctx.read<AuthRepository>(),
          ),
        ),

        // ── Video Feed ────────────────────────────────────────────────────
        Provider<VideoFeedRepository>(
          create: (_) => VideoFeedRepository(),
        ),
        ChangeNotifierProvider<VideoFeedController>(
          create: (ctx) => VideoFeedController(
            repository: ctx.read<VideoFeedRepository>(),
          )..startSuggestedFeed(),
        ),

        // ── Video Interactions ────────────────────────────────────────────
        Provider<VideoInteractionService>(
          create: (_) => VideoInteractionService(),
        ),
        ChangeNotifierProvider<VideoInteractionController>(
          create: (ctx) => VideoInteractionController(
            service: ctx.read<VideoInteractionService>(),
          ),
        ),

        // ── Live Engagement Counts ────────────────────────────────────────
        Provider<EngagementRepository>(
          create: (_) => FirestoreEngagementRepository(),
        ),

        // ── Video Upload ──────────────────────────────────────────────────
        Provider<VideoUploadRepository>(
          create: (_) => VideoUploadRepository(),
        ),
        Provider<VideoStorageService>(
          create: (_) => VideoStorageService(),
        ),
        ChangeNotifierProvider<VideoUploadController>(
          create: (ctx) => VideoUploadController(
            repository: ctx.read<VideoUploadRepository>(),
            storageService: ctx.read<VideoStorageService>(),
          ),
        ),

        // ── Creator Profile ───────────────────────────────────────────────────
        Provider<CreatorProfileRepository>(
          create: (_) => CreatorProfileRepository(),
        ),
        Provider<FollowRepository>(
          create: (_) => FollowRepository(),
        ),
        ChangeNotifierProvider<CreatorProfileController>(
          create: (ctx) => CreatorProfileController(
            followRepository: ctx.read<FollowRepository>(),
          ),
        ),

        // ── Comments ──────────────────────────────────────────────────────
        Provider<CommentRepository>(
          create: (_) => CommentRepository(),
        ),
        ChangeNotifierProvider<CommentsController>(
          create: (ctx) => CommentsController(
            repository: ctx.read<CommentRepository>(),
          ),
        ),

        // ── Notifications ─────────────────────────────────────────────────
        Provider<NotificationService>(
          create: (_) => NotificationService(),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (ctx) => NotificationController(
            service: ctx.read<NotificationService>(),
          ),
        ),

        // ── AI Creator Studio ─────────────────────────────────────────────
        Provider<AiVideoRepository>(
          create: (_) => AiVideoRepository(),
        ),
        Provider<AiCreatorApiService>(
          // Replace with your project ID — find it in Firebase console > Functions
          create: (_) => AiCreatorApiService(
            baseUrl: _yohPalEnvironment.functionsBaseUrl,
          ),
        ),
        Provider<AiCaptionService>(
          create: (ctx) => AiCaptionService(
            repository: ctx.read<AiVideoRepository>(),
            api: ctx.read<AiCreatorApiService>(),
          ),
        ),
        Provider<AiHookService>(
          create: (ctx) => AiHookService(
            repository: ctx.read<AiVideoRepository>(),
            api: ctx.read<AiCreatorApiService>(),
          ),
        ),
        Provider<AiHashtagService>(
          create: (ctx) => AiHashtagService(
            repository: ctx.read<AiVideoRepository>(),
            api: ctx.read<AiCreatorApiService>(),
          ),
        ),
        Provider<AiViralScoreService>(
          create: (ctx) => AiViralScoreService(
            repository: ctx.read<AiVideoRepository>(),
            api: ctx.read<AiCreatorApiService>(),
          ),
        ),
        Provider<AiThumbnailService>(
          create: (ctx) => AiThumbnailService(
            repository: ctx.read<AiVideoRepository>(),
            api: ctx.read<AiCreatorApiService>(),
          ),
        ),
        Provider<AiTrimService>(
          create: (ctx) => AiTrimService(
            repository: ctx.read<AiVideoRepository>(),
            api: ctx.read<AiCreatorApiService>(),
          ),
        ),
        Provider<AiPublishRepository>(
          create: (_) => AiPublishRepository(),
        ),
        ChangeNotifierProvider<AiEditorController>(
          create: (ctx) => AiEditorController(
            repository: ctx.read<AiVideoRepository>(),
            captionService: ctx.read<AiCaptionService>(),
            hookService: ctx.read<AiHookService>(),
            hashtagService: ctx.read<AiHashtagService>(),
            viralScoreService: ctx.read<AiViralScoreService>(),
            thumbnailService: ctx.read<AiThumbnailService>(),
            trimService: ctx.read<AiTrimService>(),
            publishRepository: ctx.read<AiPublishRepository>(),
          ),
        ),

        // ── Live Streaming ────────────────────────────────────────────────
        Provider<LiveRepository>(
          create: (_) => LiveRepository(),
        ),
        Provider<LiveChatRepository>(
          create: (_) => LiveChatRepository(),
        ),
        Provider<LiveGiftRepository>(
          create: (_) => LiveGiftRepository(),
        ),
        Provider<GiftService>(
          create: (_) => GiftService(),
        ),
        Provider<LiveTokenService>(
          create: (_) => LiveTokenService(
            functionsBaseUrl: _yohPalEnvironment.functionsBaseUrl,
          ),
        ),
        ChangeNotifierProvider<LiveStreamController>(
          create: (ctx) => LiveStreamController(
            repository: ctx.read<LiveRepository>(),
            tokenService: ctx.read<LiveTokenService>(),
            liveKitUrl: _yohPalEnvironment.liveKitUrl,
          ),
        ),

        // ── Live Commerce ─────────────────────────────────────────────────
        Provider<LiveCommerceRepository>(
          create: (_) => LiveCommerceRepository(),
        ),
        ChangeNotifierProvider<LiveCommerceController>(
          create: (ctx) => LiveCommerceController(
            repository: ctx.read<LiveCommerceRepository>(),
          ),
        ),

        // ── Affiliate ─────────────────────────────────────────────────────
        Provider<AffiliateRepository>(
          create: (_) => AffiliateRepository(),
        ),
        Provider<AffiliateService>(
          create: (ctx) => AffiliateService(
            repository: ctx.read<AffiliateRepository>(),
          ),
        ),
        ChangeNotifierProvider<AffiliateController>(
          create: (ctx) => AffiliateController(
            service: ctx.read<AffiliateService>(),
          ),
        ),

        // ── Contacts Growth ───────────────────────────────────────────────
        Provider<ContactImportService>(
          create: (_) => ContactImportService(),
        ),
        Provider<AiInviteRanker>(
          create: (_) => AiInviteRanker(),
        ),
        Provider<ContactsRepository>(
          create: (ctx) => ContactsRepository(
            ranker: ctx.read<AiInviteRanker>(),
          ),
        ),
        ChangeNotifierProvider<ContactsController>(
          create: (ctx) => ContactsController(
            importService: ctx.read<ContactImportService>(),
            repository: ctx.read<ContactsRepository>(),
          ),
        ),

        // ── Multistreaming ────────────────────────────────────────────────
        Provider<MultistreamRepository>(
          create: (_) => MultistreamRepository(),
        ),
        Provider<MultistreamService>(
          create: (_) => MultistreamService(
            functionsBaseUrl: _yohPalEnvironment.functionsBaseUrl,
          ),
        ),
        // ── Ads ───────────────────────────────────────────────────────────
        Provider<AdsRepository>(
          create: (_) => AdsRepository(),
        ),
        Provider<AdDeliveryService>(
          create: (_) => AdDeliveryService(),
        ),
        ChangeNotifierProvider<AdsController>(
          create: (ctx) => AdsController(
            repository: ctx.read<AdsRepository>(),
            deliveryService: ctx.read<AdDeliveryService>(),
          ),
        ),
        Provider<RewardedAdsRepository>(
          create: (_) => RewardedAdsRepository(),
        ),
        ChangeNotifierProvider<RewardedAdsController>(
          create: (ctx) => RewardedAdsController(
            repository: ctx.read<RewardedAdsRepository>(),
          ),
        ),

        // ── Wallet ────────────────────────────────────────────────────────
        Provider<YohPalWebHandoff>(
          create: (_) => YohPalWebHandoff(environment: _yohPalEnvironment),
        ),
        Provider<WalletRepository>(
          create: (_) => WalletRepository(),
        ),
        Provider<WalletService>(
          create: (ctx) => WalletService(
            handoff: ctx.read<YohPalWebHandoff>(),
          ),
        ),
        ChangeNotifierProvider<WalletController>(
          create: (ctx) => WalletController(
            service: ctx.read<WalletService>(),
          ),
        ),
        Provider<SubscriptionRepository>(
          create: (_) => SubscriptionRepository(),
        ),

        // ── Monetisation ──────────────────────────────────────────────────
        Provider<CreatorEarningsRepository>(
          create: (_) => CreatorEarningsRepository(),
        ),
        Provider<MonetisationService>(
          create: (_) => MonetisationService(),
        ),
        ChangeNotifierProvider<CreatorEarningsController>(
          create: (ctx) => CreatorEarningsController(
            repository: ctx.read<CreatorEarningsRepository>(),
          ),
        ),

        ChangeNotifierProvider<MultistreamController>(
          create: (ctx) => MultistreamController(
            repository: ctx.read<MultistreamRepository>(),
            service: ctx.read<MultistreamService>(),
          ),
        ),

        // ── Chat ─────────────────────────────────────────────────────────
        Provider<ChatRepository>(
          create: (_) => ChatRepository(),
        ),
        ChangeNotifierProvider<ChatController>(
          create: (ctx) => ChatController(
            repository: ctx.read<ChatRepository>(),
          ),
        ),

        // ── Search ────────────────────────────────────────────────────────
        Provider<SearchRepository>(
          create: (_) => SearchRepository(),
        ),
        Provider<SearchService>(
          create: (ctx) => SearchService(
            repository: ctx.read<SearchRepository>(),
          ),
        ),
        ChangeNotifierProvider<YohPalSearchController>(
          create: (ctx) => YohPalSearchController(
            service: ctx.read<SearchService>(),
          ),
        ),

        // ── Polls ─────────────────────────────────────────────────────────
        Provider<PollRepository>(
          create: (_) => PollRepository(),
        ),
        ChangeNotifierProvider<PollController>(
          create: (ctx) => PollController(
            repository: ctx.read<PollRepository>(),
          ),
        ),

        // ── Notification Inbox ────────────────────────────────────────────
        Provider<NotificationInboxRepository>(
          create: (_) => NotificationInboxRepository(),
        ),
        ChangeNotifierProvider<NotificationInboxController>(
          create: (ctx) => NotificationInboxController(
            repository: ctx.read<NotificationInboxRepository>(),
          ),
        ),

        // ── Engagement Rail (Phase 1J) ────────────────────────────────────
        Provider<PrivateEngagementRepository>(
          create: (_) => PrivateEngagementRepository(),
        ),
        ChangeNotifierProvider<VideoEngagementRailController>(
          create: (ctx) => VideoEngagementRailController(
            privateRepository: ctx.read<PrivateEngagementRepository>(),
          ),
        ),

        // ── YCIOS — AI Creator Intelligence OS (Phase 1) ─────────────────
        Provider<YciosRepository>(
          create: (_) => YciosRepository(),
        ),
        ChangeNotifierProvider<YciosController>(
          create: (ctx) => YciosController(
            repository: ctx.read<YciosRepository>(),
          ),
        ),

        // ── Phase 1L: Zero-Wait Video Playback Engine ─────────────────────
        ChangeNotifierProvider<ZeroWaitPlaybackController>(
          create: (_) => ZeroWaitPlaybackController(),
        ),
        Provider<PlaybackDiagnosticsRepository>(
          create: (_) => PlaybackDiagnosticsRepository(),
        ),

        // ── Phase 1P: Predictive Experience Engine ────────────────────────
        Provider<PredictiveNavigationEngine>(
          create: (_) => PredictiveNavigationEngine(),
        ),
        Provider<PredictiveAssetCache>(
          create: (_) => PredictiveAssetCache(),
        ),
        Provider<AdaptiveMemoryManager>(
          create: (_) => AdaptiveMemoryManager(),
        ),
        Provider<AppPerformanceRepository>(
          create: (_) => AppPerformanceRepository(),
        ),
        ChangeNotifierProvider<PredictiveExperienceController>(
          create: (ctx) => PredictiveExperienceController(
            navigationEngine: ctx.read<PredictiveNavigationEngine>(),
            assetCache: ctx.read<PredictiveAssetCache>(),
            memoryManager: ctx.read<AdaptiveMemoryManager>(),
          ),
        ),

        // ── Phase 1R: Context Intelligence ───────────────────────────────
        Provider<ContextIntelligenceEngine>(
          create: (_) => ContextIntelligenceEngine(),
        ),
        Provider<ContextActionEngine>(
          create: (_) => ContextActionEngine(),
        ),
        Provider<ContextAnalyticsRepository>(
          create: (_) => ContextAnalyticsRepository(),
        ),
        ChangeNotifierProvider<ContextIntelligenceController>(
          create: (ctx) => ContextIntelligenceController(
            intelligenceEngine: ctx.read<ContextIntelligenceEngine>(),
            actionEngine: ctx.read<ContextActionEngine>(),
            analyticsRepository: ctx.read<ContextAnalyticsRepository>(),
          ),
        ),
      ],
      child: Consumer3<AuthController, NotificationController,
          YohPalThemeController>(
        builder: (context, auth, notifications, themeModeController, _) {
          // Guard inside NotificationController prevents multiple calls.
          if (auth.user != null) {
            notifications.initializeForUser(
              uid: auth.user!.uid,
              navigatorKey: rootNavigatorKey,
            );
          }
          // Assigned once — the target controllers don't exist yet when
          // AuthController itself is constructed, so this can't happen in
          // AuthController's own constructor.
          auth.sessionCleanupService ??= YohPalSessionCleanupService(
            stores: [
              context.read<VideoFeedController>(),
              context.read<ZeroWaitPlaybackController>(),
              notifications,
              context.read<YohPalSearchController>(),
            ],
          );
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            title: 'YohPal Live',
            debugShowCheckedModeBanner: false,
            theme: YohPalTheme.day(),
            darkTheme: YohPalTheme.night(),
            themeMode: themeModeController.themeMode,
            // home handles '/' — Flutter forbids '/' in routes when home is set
            home: YohPalBootstrap(
                    warmupService: FeedStartupWarmupService(
                      feedRepository: context.read<VideoFeedRepository>(),
                      zeroWaitController: context.read<ZeroWaitPlaybackController>(),
                    ),
                    child: const AuthGate(child: YohPalMainShell()),
                  ),
            routes: {
              LoginScreen.routeName: (_) => const LoginScreen(),
              SignupScreen.routeName: (_) => const SignupScreen(),
              ...YohPalRouter.routes,
                '/mesh-live': (_) => const HomePage(),
                '/mesh-live/create': (_) => const DirectorSetupPage(),
                '/mesh-live/join-camera': (_) => const CameraJoinPage(),
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute<void>(
                builder: (_) => UnknownRouteScreen(
                  attemptedRoute: settings.name,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
