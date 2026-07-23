class EvidenceGap {
  final String title;
  final bool complete;

  const EvidenceGap({
    required this.title,
    required this.complete,
  });
}

final outstandingEvidence = <EvidenceGap>[
  EvidenceGap(
    title: 'Android device validation',
    complete: false,
  ),
  EvidenceGap(
    title: 'iPhone device validation',
    complete: false,
  ),
  EvidenceGap(
    title: 'Crashlytics verification',
    complete: false,
  ),
  EvidenceGap(
    title: 'Authentication verification',
    complete: false,
  ),
  EvidenceGap(
    title: 'Operational readiness',
    complete: false,
  ),
  EvidenceGap(
    title: 'Rollback verification',
    complete: false,
  ),
];
