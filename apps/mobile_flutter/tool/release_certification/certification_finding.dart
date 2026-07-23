enum Severity {
  critical,
  high,
  medium,
  low,
}

enum FindingStatus {
  pending,
  passed,
  failed,
  acceptedRisk,
}

final class CertificationFinding {
  const CertificationFinding({
    required this.id,
    required this.title,
    required this.severity,
    required this.status,
    required this.evidence,
    this.owner,
    this.deadline,
    this.notes,
  });

  final String id;
  final String title;
  final Severity severity;
  final FindingStatus status;
  final List<String> evidence;
  final String? owner;
  final DateTime? deadline;
  final String? notes;

  bool get isBlocking {
    if (severity == Severity.critical) {
      return status != FindingStatus.passed;
    }
    if (severity == Severity.high) {
      return status == FindingStatus.failed || status == FindingStatus.pending;
    }
    return false;
  }
}
