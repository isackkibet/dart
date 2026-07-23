/// Runtime-available release identity for RC2 certification builds.
///
/// Values are supplied through --dart-define at build time so the same binary
/// shape can be used for developer, staging, and certification builds without
/// a source change.
final class QaReleaseIdentity {
  const QaReleaseIdentity._();

  static const String releaseTag = String.fromEnvironment(
    'YOHPAL_RELEASE_TAG',
    defaultValue: '',
  );

  static const String commitHash = String.fromEnvironment(
    'YOHPAL_COMMIT_HASH',
    defaultValue: '',
  );

  static const String buildId = String.fromEnvironment(
    'YOHPAL_BUILD_ID',
    defaultValue: '',
  );

  static const String environment = String.fromEnvironment(
    'YOHPAL_ENVIRONMENT',
    defaultValue: '',
  );

  static void validateRc2() {
    if (releaseTag != 'yohpal-live-v1.0j-rc2') {
      throw StateError('Unexpected YohPal Live release tag.');
    }
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commitHash)) {
      throw StateError('A full Git commit hash is required.');
    }
    if (buildId.isEmpty || environment.isEmpty) {
      throw StateError('Build provenance is incomplete.');
    }
  }

  static Map<String, String> toJson() => {
        'releaseTag': releaseTag,
        'commitHash': commitHash,
        'buildId': buildId,
        'environment': environment,
      };
}
