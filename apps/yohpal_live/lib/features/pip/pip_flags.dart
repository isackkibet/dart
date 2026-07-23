class PipFlags {
  static const bool iosEnabled = bool.fromEnvironment(
    'YOHPAL_IOS_PIP_ENABLED',
    defaultValue: false,
  );
}
