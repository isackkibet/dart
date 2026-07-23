import 'certification_finding.dart';

enum ReleaseDecision {
  go,
  conditionalGo,
  noGo,
}

final class ReleaseDecisionInput {
  const ReleaseDecisionInput({
    required this.findings,
    required this.androidPassed,
    required this.iosPassed,
    required this.crashlyticsPassed,
    required this.securityPassed,
    required this.ciPassed,
    required this.rollbackPassed,
  });

  final List<CertificationFinding> findings;
  final bool androidPassed;
  final bool iosPassed;
  final bool crashlyticsPassed;
  final bool securityPassed;
  final bool ciPassed;
  final bool rollbackPassed;
}

ReleaseDecision decideRelease(ReleaseDecisionInput input) {
  final criticalNotPassed = input.findings.any(
    (finding) =>
        finding.severity == Severity.critical &&
        finding.status != FindingStatus.passed,
  );

  if (criticalNotPassed ||
      !input.androidPassed ||
      !input.iosPassed ||
      !input.crashlyticsPassed ||
      !input.securityPassed ||
      !input.ciPassed ||
      !input.rollbackPassed) {
    return ReleaseDecision.noGo;
  }

  final openHigh = input.findings.where(
    (finding) =>
        finding.severity == Severity.high &&
        finding.status != FindingStatus.passed,
  );

  if (openHigh.isEmpty) {
    return ReleaseDecision.go;
  }

  final conditionallyAcceptable = openHigh.length <= 2 &&
      openHigh.every(
        (finding) =>
            finding.status == FindingStatus.acceptedRisk &&
            finding.owner != null &&
            finding.deadline != null,
      );

  return conditionallyAcceptable
      ? ReleaseDecision.conditionalGo
      : ReleaseDecision.noGo;
}
