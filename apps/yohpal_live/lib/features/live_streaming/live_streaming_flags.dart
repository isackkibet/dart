class LiveStreamingFlags {
  static const bool enabled = bool.fromEnvironment(
    'YOHPAL_LIVE_STREAMING_ENABLED',
    defaultValue: false,
  );
  static const bool giftsEnabled = bool.fromEnvironment(
    'YOHPAL_LIVE_GIFTS_ENABLED',
    defaultValue: false,
  );
  static const bool chatEnabled = bool.fromEnvironment(
    'YOHPAL_LIVE_CHAT_ENABLED',
    defaultValue: true,
  );
}
