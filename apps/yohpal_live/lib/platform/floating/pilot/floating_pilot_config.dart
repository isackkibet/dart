class FloatingPilotConfig {
  final bool enabled;
  final int rolloutPercentage;
  final Set<String> allowListedUsers;
  final Set<String> enabledModules;
  final bool emergencyDisabled;
  const FloatingPilotConfig({
    required this.enabled,
    required this.rolloutPercentage,
    required this.allowListedUsers,
    required this.enabledModules,
    this.emergencyDisabled = false,
  });
  bool isEligible({
    required String uid,
    required String module,
  }) {
    if (!enabled || emergencyDisabled) return false;
    if (!enabledModules.contains(module)) return false;
    if (allowListedUsers.contains(uid)) return true;
    return (uid.hashCode.abs() % 100) < rolloutPercentage;
  }
}
