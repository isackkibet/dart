// Generates the machine-readable RC1 certification manifest from live git and
// CI evidence state. Run from the mobile_flutter directory:
//
//   dart run tool/release_certification/rc1_manifest.dart \
//     [--ci-passed] [--out <path>]
//
// Without --ci-passed the manifest records ciPassed=false and is suitable for
// a work-in-progress evidence pass. Pass --ci-passed once all non-device CI
// tasks have completed and their outputs have been archived.
import 'dart:convert';
import 'dart:io';

const _expectedBranch = 'release/yohpal-live-1.0g-rc1';
const _expectedTag = 'yohpal-live-v1.0.0-rc1';
const _releaseLabel = 'YohPal Live 1.0G-RC1';
const _evidenceRoot = 'release-evidence/yohpal-live-1.0g-rc1';

void main(List<String> args) {
  final ciPassed = args.contains('--ci-passed');
  final outIndex = args.indexOf('--out');
  final outPath =
      outIndex >= 0 && outIndex + 1 < args.length ? args[outIndex + 1] : null;

  stdout.writeln('RC1 Manifest Generator');
  stdout.writeln('=' * 60);

  // ── Git identity ──────────────────────────────────────────────────────────
  final branch = _git(['rev-parse', '--abbrev-ref', 'HEAD']).trim();
  final commitHash = _git(['rev-parse', 'HEAD']).trim();
  final tagAtHead = _git(['tag', '--points-at', 'HEAD']).trim();

  stdout.writeln('Branch:      $branch');
  stdout.writeln('Commit SHA:  $commitHash');
  stdout.writeln('Tag at HEAD: ${tagAtHead.isEmpty ? "(none)" : tagAtHead}');

  // ── Branch / tag validation ───────────────────────────────────────────────
  final branchOk = branch == _expectedBranch;
  final tagOk = tagAtHead == _expectedTag;

  if (!branchOk) {
    stderr.writeln(
      'WARNING: Current branch "$branch" is not the required release branch '
      '"$_expectedBranch". Create the release branch before final submission.',
    );
  }
  if (!tagOk) {
    stderr.writeln(
      'WARNING: No tag "$_expectedTag" points at HEAD. '
      'Apply the tag before final submission.',
    );
  }

  // ── CI evidence file probing ──────────────────────────────────────────────
  final ciOutputs = {
    'format': '$_evidenceRoot/ci-outputs/format.txt',
    'analyze': '$_evidenceRoot/ci-outputs/analyze.txt',
    'test': '$_evidenceRoot/ci-outputs/test.txt',
    'coverage': '$_evidenceRoot/coverage/summary.txt',
    'routes': '$_evidenceRoot/ci-outputs/routes.txt',
    'functions-build': '$_evidenceRoot/ci-outputs/functions-build.txt',
    'functions-test': '$_evidenceRoot/ci-outputs/functions-test.txt',
  };

  final ciArtifactsPresent = ciOutputs.values.every(
    (path) => File(path).existsSync(),
  );

  stdout.writeln(
    'CI artifact files present: ${ciArtifactsPresent ? "YES" : "NO (some missing)"}',
  );

  // ── External evidence placeholder status ─────────────────────────────────
  // These can never be satisfied by this tool — they require real device and
  // operational evidence. We record their target paths so the manifest is
  // self-describing about what remains outstanding.
  final externalEvidence = {
    'androidReport': '$_evidenceRoot/android/report.json',
    'iosReport': '$_evidenceRoot/ios/report.json',
    'crashlyticsProof': '$_evidenceRoot/observability/',
    'securityReport': '$_evidenceRoot/security/security-report.md',
    'rrbResolution': '$_evidenceRoot/governance/rrb-resolution.md',
  };

  final externalPresent = externalEvidence.values
      .every((path) => File(path).existsSync() || Directory(path).existsSync());

  // ── Build manifest ────────────────────────────────────────────────────────
  final manifest = <String, dynamic>{
    'release': _releaseLabel,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'branch': branch,
    'branchValid': branchOk,
    'commitHash': commitHash,
    'tag': tagAtHead.isEmpty ? null : tagAtHead,
    'tagValid': tagOk,
    'ciPassed': ciPassed && ciArtifactsPresent,
    'ciArtifactsPresent': ciArtifactsPresent,
    'ciOutputs': ciOutputs,
    'externalEvidencePresent': externalPresent,
    ...externalEvidence,
  };

  final prettyJson =
      const JsonEncoder.withIndent('  ').convert(manifest);

  // ── Output ────────────────────────────────────────────────────────────────
  stdout.writeln('=' * 60);
  if (outPath != null) {
    final outFile = File(outPath);
    outFile.parent.createSync(recursive: true);
    outFile.writeAsStringSync('$prettyJson\n');
    stdout.writeln('Manifest written to: $outPath');
  } else {
    stdout.writeln(prettyJson);
  }

  final readyForSubmission = branchOk && tagOk && ciPassed && ciArtifactsPresent && externalPresent;
  stdout.writeln('=' * 60);
  stdout.writeln(
    'Submission readiness: ${readyForSubmission ? "READY" : "NOT READY — see warnings above"}',
  );

  if (!readyForSubmission) exitCode = 1;
}

String _git(List<String> args) {
  final result = Process.runSync('git', args);
  if (result.exitCode != 0) return '';
  return (result.stdout as String).trim();
}
