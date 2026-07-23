import 'identity/yohpal_identity_service.dart';
import 'wallet/yohpal_wallet_service.dart';
import 'notifications/yohpal_notification_service.dart';
import 'search/yohpal_search_service.dart';
import 'brain/yohpal_brain_gateway.dart';
import 'analytics/yohpal_analytics_service.dart';
import 'deep_links/yohpal_deep_link_service.dart';

// Single entry point for all platform services.
// Modules access platform capabilities exclusively through this registry —
// never by instantiating services directly or calling providers independently.
//
// Usage in a module:
//   final platform = context.read<YohPalPlatformRegistry>();
//   final identity = await platform.identity.getCurrentIdentity();
//   final balance  = await platform.wallet.getBalance(identity!.uid);
class YohPalPlatformRegistry {
  final YohPalIdentityService identity;
  final YohPalWalletService wallet;
  final YohPalNotificationService notifications;
  final YohPalSearchService search;
  final YohPalBrainGateway brain;
  final YohPalAnalyticsService analytics;
  final YohPalDeepLinkService deepLinks;

  const YohPalPlatformRegistry({
    required this.identity,
    required this.wallet,
    required this.notifications,
    required this.search,
    required this.brain,
    required this.analytics,
    required this.deepLinks,
  });
}
