import 'package:flutter/material.dart';
import 'package:yohpal_live/platform/platform_provider.dart';
import 'package:yohpal_live/platform/identity/firebase_identity_service.dart';
import 'package:yohpal_live/platform/wallet/firebase_wallet_service.dart';
import 'package:yohpal_live/platform/notifications/firebase_notification_service.dart';
import 'package:yohpal_live/platform/search/firebase_search_service.dart';
import 'package:yohpal_live/platform/brain/firebase_brain_gateway.dart';
import 'package:yohpal_live/platform/analytics/firebase_analytics_service.dart';
import 'package:yohpal_live/platform/deep_links/default_deep_link_service.dart';
import 'package:yohpal_live/features/live_streaming/app_routes.dart';
import 'package:yohpal_live/features/live_streaming/live_streaming_gate.dart';
import 'package:yohpal_live/features/live_streaming/screens/live_streaming_hub_screen.dart';
import 'package:yohpal_live/features/live_streaming/screens/go_live_screen.dart';
import 'package:yohpal_live/features/live_streaming/screens/live_viewer_screen.dart';

class YohPalApp extends StatelessWidget {
  const YohPalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YohPal Live',
      routes: {
        AppRoutes.liveStreaming: (_) => const LiveStreamingGate(
              child: LiveStreamingHubScreen(),
            ),
        AppRoutes.goLive: (_) => const LiveStreamingGate(
              child: GoLiveScreen(),
            ),
        AppRoutes.liveViewer: (_) => const LiveStreamingGate(
              child: LiveViewerScreen(),
            ),
      },
      home: const Scaffold(
        body: Center(child: Text('YohPal Live')),
      ),
    );
  }
}

void main() {
  runApp(
    YohPalPlatformProvider(
      identity: FirebaseIdentityService(),
      wallet: FirebaseWalletService(),
      notifications: FirebaseNotificationService(),
      search: FirebaseSearchService(),
      brain: FirebaseBrainGateway(),
      analytics: FirebaseAnalyticsService(),
      deepLinks: DefaultDeepLinkService(),
      child: const YohPalApp(),
    ),
  );
}
