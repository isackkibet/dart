
class MinorPublicationController {
  const MinorPublicationController();

  List<String> evaluateGate({
    required bool classificationCompleted,
    required bool minorDirected,
    required bool containsIdentifiableMinor,
    required String ageRating,
    required String creatorVerificationStatus,
    required bool guardianConsentRequired,
    required bool guardianConsentVerified,
    required bool manualReviewRequired,
    required bool manualReviewPassed,
  }) {
    final blockers = <String>[];

    if (!classificationCompleted) {
      blockers.add('Age and minor-content classification is incomplete.');
    }
    if (minorDirected && creatorVerificationStatus != 'approved') {
      blockers.add('The creator is not approved for minor-directed content.');
    }
    if (containsIdentifiableMinor && guardianConsentRequired && !guardianConsentVerified) {
      blockers.add('Required guardian consent has not been verified.');
    }
    if (manualReviewRequired && !manualReviewPassed) {
      blockers.add('Mandatory child-safety review is incomplete.');
    }
    if (ageRating.isEmpty) {
      blockers.add('An age rating is required.');
    }

    return blockers;
  }

  bool canPublish({
    required bool minorDirected,
    required bool creatorVerified,
    required bool guardianConsentVerified,
    required bool manualReviewPassed,
    required bool classificationCompleted,
    required String ageRating,
  }) {
    final blockers = evaluateGate(
      classificationCompleted: classificationCompleted,
      minorDirected: minorDirected,
      containsIdentifiableMinor: true,
      ageRating: ageRating,
      creatorVerificationStatus: creatorVerified ? 'approved' : 'pending',
      guardianConsentRequired: minorDirected,
      guardianConsentVerified: guardianConsentVerified,
      manualReviewRequired: minorDirected,
      manualReviewPassed: manualReviewPassed,
    );
    return blockers.isEmpty;
  }
}
