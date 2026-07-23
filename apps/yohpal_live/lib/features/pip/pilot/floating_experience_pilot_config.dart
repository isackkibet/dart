class FloatingExperiencePilotConfig {
  final bool enabled;
  final int rolloutPercentage;
  final Set<String> allowListedUsers;
  const FloatingExperiencePilotConfig({
    required this.enabled,
    required this.rolloutPercentage,
    required this.allowListedUsers,
  });
  bool isEligible(String uid) {
    if (!enabled) return false;
    if (allowListedUsers.contains(uid)) {
      return true;
    }
    return (uid.hashCode.abs() % 100) < rolloutPercentage;
  }
}
