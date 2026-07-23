import 'package:flutter/material.dart';
import 'identity/yohpal_identity_service.dart';
import 'wallet/yohpal_wallet_service.dart';
import 'notifications/yohpal_notification_service.dart';
import 'search/yohpal_search_service.dart';
import 'brain/yohpal_brain_gateway.dart';
import 'analytics/yohpal_analytics_service.dart';
import 'deep_links/yohpal_deep_link_service.dart';

class YohPalPlatformProvider extends InheritedWidget {
  final YohPalIdentityService identity;
  final YohPalWalletService wallet;
  final YohPalNotificationService notifications;
  final YohPalSearchService search;
  final YohPalBrainGateway brain;
  final YohPalAnalyticsService analytics;
  final YohPalDeepLinkService deepLinks;
  const YohPalPlatformProvider({
    super.key,
    required this.identity,
    required this.wallet,
    required this.notifications,
    required this.search,
    required this.brain,
    required this.analytics,
    required this.deepLinks,
    required super.child,
  });
  static YohPalPlatformProvider of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<YohPalPlatformProvider>();
    assert(provider != null, 'YohPalPlatformProvider not found');
    return provider!;
  }
  @override
  bool updateShouldNotify(YohPalPlatformProvider oldWidget) => false;
}
