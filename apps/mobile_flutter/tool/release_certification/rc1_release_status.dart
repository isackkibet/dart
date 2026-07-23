enum Rc1ReleaseState {
  implementationComplete,
  evidenceCollection,
  reviewBoard,
  certified,
  rejected,
}

class Rc1ReleaseStatus {
  final Rc1ReleaseState state;
  final bool repositoryFrozen;
  final bool releaseTagged;
  final bool ciValidated;
  final bool androidValidated;
  final bool iosValidated;
  final bool crashlyticsVerified;

  const Rc1ReleaseStatus({
    required this.state,
    required this.repositoryFrozen,
    required this.releaseTagged,
    required this.ciValidated,
    required this.androidValidated,
    required this.iosValidated,
    required this.crashlyticsVerified,
  });

  bool get readyForBoard =>
      repositoryFrozen &&
      releaseTagged &&
      ciValidated &&
      androidValidated &&
      iosValidated &&
      crashlyticsVerified;
}
