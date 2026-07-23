class PipRolloutController {
  final bool enabled;
  final int rolloutPercentage;
  final Set<String> allowListedUsers;
  const PipRolloutController({
    required this.enabled,
    required this.rolloutPercentage,
    required this.allowListedUsers,
  });
  bool isEnabledFor(String uid) {
    if (!enabled) return false;
    if (allowListedUsers.contains(uid)) {
      return true;
    }
    return (uid.hashCode.abs() % 100) < rolloutPercentage;
  }
}
