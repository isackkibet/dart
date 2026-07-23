import 'package:flutter_test/flutter_test.dart';
import '../../tool/release_certification/certification_finding.dart';
import '../../tool/release_certification/release_decision_engine.dart';

CertificationFinding _finding({
  required Severity severity,
  required FindingStatus status,
  String? owner,
  DateTime? deadline,
}) {
  return CertificationFinding(
    id: 'f',
    title: 'test finding',
    severity: severity,
    status: status,
    evidence: const [],
    owner: owner,
    deadline: deadline,
  );
}

void main() {
  group('decideRelease', () {
    test('no-go when a Critical finding has not passed', () {
      final decision = decideRelease(
        ReleaseDecisionInput(
          findings: [
            _finding(
                severity: Severity.critical, status: FindingStatus.pending),
          ],
          androidPassed: true,
          iosPassed: true,
          crashlyticsPassed: true,
          securityPassed: true,
          ciPassed: true,
          rollbackPassed: true,
        ),
      );
      expect(decision, ReleaseDecision.noGo);
    });

    test(
        'no-go when device/observability/security/ci/rollback gates are unproven, '
        'even with zero findings', () {
      final decision = decideRelease(
        const ReleaseDecisionInput(
          findings: [],
          androidPassed: false,
          iosPassed: false,
          crashlyticsPassed: false,
          securityPassed: false,
          ciPassed: false,
          rollbackPassed: false,
        ),
      );
      expect(decision, ReleaseDecision.noGo);
    });

    test(
        'go when all Criticals pass, no High findings open, and all gates pass',
        () {
      final decision = decideRelease(
        ReleaseDecisionInput(
          findings: [
            _finding(severity: Severity.critical, status: FindingStatus.passed),
          ],
          androidPassed: true,
          iosPassed: true,
          crashlyticsPassed: true,
          securityPassed: true,
          ciPassed: true,
          rollbackPassed: true,
        ),
      );
      expect(decision, ReleaseDecision.go);
    });

    test(
        'conditional-go when up to two High findings are formally accepted risk',
        () {
      final decision = decideRelease(
        ReleaseDecisionInput(
          findings: [
            _finding(severity: Severity.critical, status: FindingStatus.passed),
            _finding(
              severity: Severity.high,
              status: FindingStatus.acceptedRisk,
              owner: 'someone',
              deadline: DateTime(2026, 8, 1),
            ),
          ],
          androidPassed: true,
          iosPassed: true,
          crashlyticsPassed: true,
          securityPassed: true,
          ciPassed: true,
          rollbackPassed: true,
        ),
      );
      expect(decision, ReleaseDecision.conditionalGo);
    });

    test('no-go when an accepted-risk High finding has no owner or deadline',
        () {
      final decision = decideRelease(
        ReleaseDecisionInput(
          findings: [
            _finding(severity: Severity.critical, status: FindingStatus.passed),
            _finding(
                severity: Severity.high, status: FindingStatus.acceptedRisk),
          ],
          androidPassed: true,
          iosPassed: true,
          crashlyticsPassed: true,
          securityPassed: true,
          ciPassed: true,
          rollbackPassed: true,
        ),
      );
      expect(decision, ReleaseDecision.noGo);
    });
  });
}
