// Source-level snapshot of the 1.0G-RC1 Critical/High closure matrices,
// verified against actual current code (grep/read, not prior report
// narrative) on 2026-07-11. Run with:
//   dart run tool/release_certification/rc1_source_findings.dart
//
// This does NOT constitute release evidence by itself — device flags below
// are hardcoded to false because no Android/iPhone testing, Crashlytics
// console event, security review, CI run, or rollback proof exists yet.
// Update those flags (and re-run) once that evidence actually exists.
import 'dart:io';

import 'certification_finding.dart';
import 'release_decision_engine.dart';

final criticalFindings = <CertificationFinding>[
  const CertificationFinding(
    id: 'analytics-route-crash',
    title: 'Analytics route crash',
    severity: Severity.critical,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/profile/screens/profile_hub_screen.dart '
          '(pushes CreatorAnalyticsScreen.routeName, was a hardcoded '
          "mismatched string)",
      'lib/app/app.dart (onUnknownRoute fallback added)',
      'tool/check_routes.dart (automated — 56 routes verified passing)',
    ],
    notes: 'Source-fixed and automated-route-test-verified. Required '
        'evidence also asks for device proof, which does not exist yet.',
  ),
  const CertificationFinding(
    id: 'crash-reporting',
    title: 'Crash reporting',
    severity: Severity.critical,
    status: FindingStatus.pending,
    evidence: [
      'lib/main.dart (runZonedGuarded, FlutterError.onError, '
          'PlatformDispatcher.onError)',
      'lib/core/observability/yohpal_crash_reporter.dart',
      'lib/features/settings/theme_settings_screen.dart '
          '(hidden long-press verification trigger)',
    ],
    notes: 'Instrumented end to end; no Android/iPhone Crashlytics console '
        'event has actually been captured.',
  ),
  const CertificationFinding(
    id: 'password-reset',
    title: 'Password reset',
    severity: Severity.critical,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/auth/screens/forgot_password_screen.dart',
      'lib/features/auth/services/password_reset_service.dart '
          '(real sendPasswordResetEmail call)',
    ],
    notes: 'Wired end to end in code; no device email-delivery/round-trip '
        'proof exists.',
  ),
  const CertificationFinding(
    id: 'environment-configuration',
    title: 'Environment configuration',
    severity: Severity.critical,
    status: FindingStatus.passed,
    evidence: [
      'lib/core/config/yohpal_environment.dart (5 endpoints: '
          'functionsBaseUrl, liveKitUrl, walletBaseUrl, adsBaseUrl, '
          'subscriptionsBaseUrl)',
      'lib/core/web_handoff/yohpal_web_handoff.dart',
      'lib/features/live_streaming/widgets/live_product_card.dart '
          '(fixed this pass — was hardcoding wallet.yohpal.com directly, '
          'bypassing the environment abstraction entirely)',
      'grep -rn for cloudfunctions.net/livekit.cloud/wallet.yohpal.com/'
          'ads.yohpal.com/subscriptions.yohpal.com across lib/: zero '
          'matches outside yohpal_environment.dart',
    ],
    notes: 'Required evidence for this finding ("all backend/web '
        'endpoints supplied through environment config") does not depend '
        'on a device — it is fully satisfied at the source level.',
  ),
  const CertificationFinding(
    id: 'rewarded-ad-fraud-exposure',
    title: 'Rewarded-ad fraud exposure',
    severity: Severity.critical,
    status: FindingStatus.pending,
    evidence: [],
    notes: 'Explicitly out of scope this cycle — no AdMob credentials '
        'provided. Still elapsed-time validation only; no real ad SDK or '
        'cryptographic server-side verification.',
  ),
];

final highFindings = <CertificationFinding>[
  const CertificationFinding(
    id: 'search-navigation',
    title: 'Search navigation',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/video_feed/screens/video_feed_screen.dart '
          '(search icon wired to SearchScreen.routeName)',
    ],
    notes: 'Source-verified via the route-integrity gate; required proof '
        'is an Android/iPhone journey, not yet performed.',
  ),
  const CertificationFinding(
    id: 'live-discovery-navigation',
    title: 'Live Discovery navigation',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/video_feed/screens/video_feed_screen.dart '
          '(live icon wired to LiveDiscoveryScreen.routeName)',
    ],
    notes: 'Same as search navigation — source-verified, device journey '
        'not yet performed.',
  ),
  const CertificationFinding(
    id: 'feed-retry',
    title: 'Feed retry',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/video_feed/controllers/video_feed_controller.dart '
          '(retry())',
      'lib/features/video_feed/screens/video_feed_screen.dart '
          '(retry button)',
    ],
    notes: 'Source-implemented; no automated forced-network-error test '
        'exists yet, and no device proof.',
  ),
  const CertificationFinding(
    id: 'accessibility-semantics',
    title: 'Accessibility semantics',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/video_playback/widgets/zero_wait_video_player.dart '
          '(Semantics on video surface + mute button)',
      'lib/features/engagement/widgets/video_engagement_rail_widget.dart '
          '(Semantics on every rail button)',
    ],
    notes: 'Source-verified; TalkBack/VoiceOver device proof not yet '
        'performed.',
  ),
  const CertificationFinding(
    id: 'live-reconnect',
    title: 'Live reconnect',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/live_streaming/controllers/'
          'live_connection_supervisor.dart',
      'lib/features/live_streaming/controllers/live_stream_controller.dart',
      'lib/features/live_streaming/screens/live_viewer_screen.dart '
          '(reconnect banner)',
    ],
    notes: 'Verified against the installed livekit_client 2.3.1+hotfix.1 '
        'API via the analyzer; no real network-interruption device proof.',
  ),
  const CertificationFinding(
    id: 'duplicate-video-stacks',
    title: 'Duplicate video stacks',
    severity: Severity.high,
    status: FindingStatus.passed,
    evidence: [
      'git status (lib/core/video/, lib/core/video_feed/ removed — '
          '19 files, confirmed zero references before deletion)',
      'flutter analyze (clean)',
    ],
    notes: 'Required evidence (commit diff + analyzer proof) does not '
        'depend on a device and is fully satisfied.',
  ),
  const CertificationFinding(
    id: 'friendly-auth-errors',
    title: 'Friendly auth errors',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/auth/services/auth_error_mapper.dart',
      'lib/features/auth/repositories/auth_repository.dart '
          '(every catch block uses AuthErrorMapper)',
      'test/features/auth/auth_error_mapper_test.dart (7 passing tests)',
    ],
    notes: 'Source-verified with automated unit tests; required evidence '
        'specifically asks for device screenshots, which do not exist.',
  ),
  const CertificationFinding(
    id: 'input-validation',
    title: 'Input validation',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/auth/screens/forgot_password_screen.dart '
          '(full Form validation)',
    ],
    notes: 'Partial at the source level, not just missing proof: signup '
        'already validates password-match/terms, but the login screen '
        'still has zero Form/validators. Required login+signup '
        'validation tests do not exist either.',
  ),
  const CertificationFinding(
    id: 'automated-test-coverage',
    title: 'Automated test coverage',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      '41 tests passing (was 32 before this pass; +9 new)',
      'coverage/lcov.info generated (111 lines)',
    ],
    notes: 'A real coverage report now exists (source-achievable, no '
        'device needed), but coverage itself remains thin — the '
        'gift-purchase Cloud Function, wallet reconciliation, both SSO '
        'paths, and the feed/live controllers are still uncovered.',
  ),
  const CertificationFinding(
    id: 'ai-publish-gate',
    title: 'AI publish gate',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/video_editor_ai/models/ai_publish_status.dart',
      'lib/features/video_editor_ai/screens/ai_editor_screen.dart '
          '(durable, Firestore-backed gate — was ephemeral widget state)',
      'test/features/video_editor_ai/publish_eligibility_test.dart '
          '(2 passing unit tests)',
    ],
    notes: 'Source-verified with unit tests on the pure gating logic; '
        'required evidence asks for "end-to-end" proof (a real Firestore '
        'write/read cycle), which these unit tests do not exercise.',
  ),
  const CertificationFinding(
    id: 'avatar-upload',
    title: 'Avatar upload',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/creator_profile/services/creator_avatar_service.dart',
      'lib/features/creator_profile/screens/'
          'edit_creator_profile_screen.dart',
      'firestore/rules/storage.rules (confirmed profile_pictures/{uid}/ '
          'is the actually-permitted path — the obvious creatorAvatars/ '
          'path from the RC1 doc would have hit permission-denied)',
    ],
    notes: 'Source-verified, including a real runtime-failure fix; no '
        'actual device upload has been performed.',
  ),
  const CertificationFinding(
    id: 'chat-error-surfacing',
    title: 'Chat error surfacing',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/chat/screens/chat_room_screen.dart (catch + '
          'crash-log + retry banner with preserved failed text)',
    ],
    notes: 'Source-verified; no automated failed-send test or device '
        'proof exists yet.',
  ),
  const CertificationFinding(
    id: 'logout-state-clearing',
    title: 'Logout state clearing',
    severity: Severity.high,
    status: FindingStatus.pending,
    evidence: [
      'lib/features/auth/session_cleanup_service.dart',
      'lib/features/auth/controllers/auth_controller.dart (best-effort '
          'clearAll() before signOut())',
      'test/features/auth/session_cleanup_service_test.dart '
          '(2 passing unit tests)',
    ],
    notes: 'The cleanup mechanism itself is unit-tested and source-'
        'verified across the 4 controllers that actually held '
        'cross-account state (feed, playback pool, notification-token '
        'binding, search); required evidence specifically asks for a '
        'second-account isolation proof on a real device.',
  ),
];

void main() {
  final findings = [...criticalFindings, ...highFindings];

  stdout.writeln('YohPal Live 1.0G-RC1 — source-level finding snapshot');
  stdout.writeln('=' * 60);
  for (final finding in findings) {
    stdout.writeln(
      '[${finding.severity.name.toUpperCase()}] ${finding.title}: '
      '${finding.status.name}${finding.isBlocking ? ' (blocking)' : ''}',
    );
  }

  final decision = decideRelease(
    ReleaseDecisionInput(
      findings: findings,
      // None of these exist yet — see the module doc comment above.
      androidPassed: false,
      iosPassed: false,
      crashlyticsPassed: false,
      securityPassed: false,
      ciPassed: false,
      rollbackPassed: false,
    ),
  );

  stdout.writeln('=' * 60);
  stdout.writeln('Computed release decision: ${decision.name}');
}
