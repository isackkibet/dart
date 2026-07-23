class ContextualPipFlags {
  static const bool enabled = bool.fromEnvironment(
    'YOHPAL_CONTEXTUAL_PIP_ENABLED',
    defaultValue: false,
  );
  static const bool jobsEnabled = bool.fromEnvironment(
    'YOHPAL_CONTEXTUAL_PIP_JOBS',
    defaultValue: false,
  );
  static const bool hustleEnabled = bool.fromEnvironment(
    'YOHPAL_CONTEXTUAL_PIP_HUSTLE',
    defaultValue: false,
  );
  static const bool marketEnabled = bool.fromEnvironment(
    'YOHPAL_CONTEXTUAL_PIP_MARKET',
    defaultValue: false,
  );
}
