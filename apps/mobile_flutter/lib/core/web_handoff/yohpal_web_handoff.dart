import 'package:url_launcher/url_launcher.dart';
import '../config/yohpal_environment.dart';

class YohPalWebHandoff {
  YohPalWebHandoff({YohPalEnvironment? environment})
      : environment = environment ?? YohPalEnvironment.fromDefines();

  final YohPalEnvironment environment;

  String get walletBaseUrl => environment.walletBaseUrl;
  String get adsBaseUrl => environment.adsBaseUrl;
  String get subscriptionsBaseUrl => environment.subscriptionsBaseUrl;

  // YohPal Web appends `?status=success|pending|failed&reference=<id>` to
  // this exact scheme+host when it redirects back to the app after a
  // wallet action completes. YohPalDeepLinkService listens for it and
  // navigates to WalletStatusScreen. Without this, the app previously had
  // no way to know whether the browser round-trip succeeded at all
  // (Production Readiness Review, Critical #7) — the return URL has to be
  // requested by the client the same way `returnUrl` was already used for
  // subscription checkout below, it just wasn't wired to anything on this
  // end.
  static const String _returnScheme = 'yohpal';
  static const String _walletStatusHost = 'wallet-status';

  String get _walletReturnUrl => '$_returnScheme://$_walletStatusHost';

  Future<void> openWallet({required String userId}) async {
    await _open(
      '$walletBaseUrl/dashboard?userId=$userId&source=mobile'
      '&returnUrl=${Uri.encodeComponent(_walletReturnUrl)}',
    );
  }

  Future<void> openWithdrawal({required String userId}) async {
    await _open(
      '$walletBaseUrl/withdraw?userId=$userId&source=mobile'
      '&returnUrl=${Uri.encodeComponent(_walletReturnUrl)}',
    );
  }

  Future<void> openSubscriptionCheckout({
    required String creatorId,
    required String viewerId,
    required String planId,
  }) async {
    await _open(
      '$subscriptionsBaseUrl/checkout'
      '?creatorId=$creatorId'
      '&viewerId=$viewerId'
      '&planId=$planId'
      '&source=mobile',
    );
  }

  Future<void> openAdvertiserDashboard({required String advertiserId}) async {
    await _open(
        '$adsBaseUrl/dashboard?advertiserId=$advertiserId&source=mobile');
  }

  Future<void> openPaymentIntent({required String intentId}) async {
    await _open(
      '$walletBaseUrl/pay?intentId=$intentId&source=live_commerce'
      '&returnUrl=${Uri.encodeComponent(_walletReturnUrl)}',
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      throw Exception('Unable to open YohPal Web handoff');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
