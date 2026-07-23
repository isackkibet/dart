class YohPalEnv {
  YohPalEnv._();

  // Cloud Functions base (Firebase project: yohlab)
  static const String functionsBaseUrl =
      'https://us-central1-yohlab.cloudfunctions.net';

  // LiveKit cloud endpoint
  static const String liveKitUrl = 'wss://yohpal-live-ln8xib3c.livekit.cloud';

  // Web product URLs — handoff targets (web-side writes only)
  static const String walletBaseUrl = 'https://wallet.yohpal.com';
  static const String adsBaseUrl = 'https://ads.yohpal.com';
  static const String subscriptionsBaseUrl = 'https://subscriptions.yohpal.com';
}
