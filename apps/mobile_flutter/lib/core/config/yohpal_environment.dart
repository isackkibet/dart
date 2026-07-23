enum YohPalEnvironmentName {
  development,
  staging,
  production,
}

/// Centralizes the backend endpoints that used to be hardcoded inline
/// throughout lib/app/app.dart. Values come from --dart-define at build/run
/// time so the same binary shape can point at dev/staging/prod without a
/// code change — see the `flutter run --dart-define=...` example below.
final class YohPalEnvironment {
  const YohPalEnvironment({
    required this.name,
    required this.functionsBaseUrl,
    required this.liveKitUrl,
    required this.walletBaseUrl,
    required this.adsBaseUrl,
    required this.subscriptionsBaseUrl,
  });

  final YohPalEnvironmentName name;
  final String functionsBaseUrl;
  final String liveKitUrl;
  final String walletBaseUrl;
  final String adsBaseUrl;
  final String subscriptionsBaseUrl;

  static const _productionFunctionsBaseUrl =
      'https://us-central1-yohlab.cloudfunctions.net';
  static const _productionLiveKitUrl =
      'wss://yohpal-live-ln8xib3c.livekit.cloud';
  static const _productionWalletBaseUrl = 'https://wallet.yohpal.com';
  static const _productionAdsBaseUrl = 'https://ads.yohpal.com';
  static const _productionSubscriptionsBaseUrl =
      'https://subscriptions.yohpal.com';

  factory YohPalEnvironment.fromDefines() {
    const environmentName = String.fromEnvironment(
      'YOHPAL_ENV',
      defaultValue: 'production',
    );

    final name = switch (environmentName) {
      'staging' => YohPalEnvironmentName.staging,
      'development' => YohPalEnvironmentName.development,
      _ => YohPalEnvironmentName.production,
    };

    return YohPalEnvironment(
      name: name,
      functionsBaseUrl: const String.fromEnvironment(
        'YOHPAL_FUNCTIONS_BASE_URL',
        defaultValue: _productionFunctionsBaseUrl,
      ),
      liveKitUrl: const String.fromEnvironment(
        'YOHPAL_LIVEKIT_URL',
        defaultValue: _productionLiveKitUrl,
      ),
      walletBaseUrl: const String.fromEnvironment(
        'YOHPAL_WALLET_URL',
        defaultValue: _productionWalletBaseUrl,
      ),
      adsBaseUrl: const String.fromEnvironment(
        'YOHPAL_ADS_URL',
        defaultValue: _productionAdsBaseUrl,
      ),
      subscriptionsBaseUrl: const String.fromEnvironment(
        'YOHPAL_SUBSCRIPTIONS_URL',
        defaultValue: _productionSubscriptionsBaseUrl,
      ),
    );
  }
}
