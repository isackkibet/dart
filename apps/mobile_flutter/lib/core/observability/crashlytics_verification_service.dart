import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../release/qa_release_identity.dart';

/// One-time release-build proof that Crashlytics is actually wired up —
/// exists purely to produce a Firebase console event during device
/// certification. Must stay behind a hidden entry point (see
/// ThemeSettingsScreen's developer section) and should be deleted once
/// that evidence has been captured.
final class CrashlyticsVerificationService {
  const CrashlyticsVerificationService();

  Future<void> _setReleaseCustomKeys() async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey('release_tag', QaReleaseIdentity.releaseTag);
      await FirebaseCrashlytics.instance.setCustomKey('commit_hash', QaReleaseIdentity.commitHash);
      await FirebaseCrashlytics.instance.setCustomKey('build_id', QaReleaseIdentity.buildId);
      await FirebaseCrashlytics.instance.setCustomKey('environment', QaReleaseIdentity.environment);
    } catch (_) {}
  }

  Future<void> sendNonFatalVerification() async {
    QaReleaseIdentity.validateRc2();
    await _setReleaseCustomKeys();
    try {
      await FirebaseCrashlytics.instance.recordError(
        StateError('YohPal 1.0J-RC2 verification event'),
        StackTrace.current,
        fatal: false,
        reason: 'Release candidate observability proof',
      );
    } catch (_) {}
  }

  Future<void> triggerFatalVerification() async {
    QaReleaseIdentity.validateRc2();
    await _setReleaseCustomKeys();
    try { FirebaseCrashlytics.instance.crash(); } catch (_) {}
  }
}
