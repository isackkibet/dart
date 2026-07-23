final class Release10JFlags {
  const Release10JFlags._();

  static const immersiveFeed = bool.fromEnvironment(
    'YOHPAL_IMMERSIVE_FEED',
    defaultValue: false,
  );

  static const liveEngagement = bool.fromEnvironment(
    'YOHPAL_LIVE_ENGAGEMENT',
    defaultValue: false,
  );

  static const creatorAggregates = bool.fromEnvironment(
    'YOHPAL_CREATOR_AGGREGATES',
    defaultValue: false,
  );

  static const minorSafety = bool.fromEnvironment(
    'YOHPAL_MINOR_SAFETY',
    defaultValue: false,
  );

  static const minorAdvertising = bool.fromEnvironment(
    'YOHPAL_MINOR_ADVERTISING',
    defaultValue: false,
  );

  static void validateRc1() {
    if (minorAdvertising && !minorSafety) {
      throw StateError(
        'Minor advertising cannot be enabled without Minor Safety.',
      );
    }
  }
}
