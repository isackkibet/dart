import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../features/wallet_web/screens/wallet_status_screen.dart';

/// Listens for the `yohpal://` custom URL scheme and turns it into
/// in-app navigation.
///
/// Today this only handles the wallet-checkout return link
/// (`yohpal://wallet-status?status=...&reference=...`) that
/// YohPalWebHandoff now requests from YohPal Web — see the comment there.
/// This is a custom-scheme deep link, not a verified Universal Link/App
/// Link (no `apple-app-site-association` / `assetlinks.json` domain
/// verification is set up), which is the pragmatic option that works
/// without owning that server-side config today. It should be upgraded to
/// a verified https:// Universal/App Link before relying on it for
/// anything security-sensitive, since custom schemes can in principle be
/// registered by another app on the same device.
class YohPalDeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;

  void start(GlobalKey<NavigatorState> navigatorKey) {
    _subscription = _appLinks.uriLinkStream.listen((uri) {
      _handle(uri, navigatorKey);
    });
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handle(uri, navigatorKey);
    });
  }

  void _handle(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    if (uri.scheme != 'yohpal') return;
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    if (uri.host == 'wallet-status') {
      navigator.pushNamed(
        WalletStatusScreen.routeName,
        arguments: WalletStatusArgs.fromQueryParameters(uri.queryParameters),
      );
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
