enum MinorContentType {
  none,
  incidentalMinorAppearance,
  minorParticipant,
  minorCreator,
  directedToChildren,
  educationalForMinors,
  advertisingToMinors,
}

enum VideoAgeRating {
  earlyChildhood,
  children,
  preTeen,
  teen,
  general,
  mature,
  adultsOnly,
}

extension VideoAgeRatingLabel on VideoAgeRating {
  String get label {
    switch (this) {
      case VideoAgeRating.earlyChildhood:
        return 'Early Childhood';
      case VideoAgeRating.children:
        return 'Children';
      case VideoAgeRating.preTeen:
        return 'Pre-Teen';
      case VideoAgeRating.teen:
        return 'Teen';
      case VideoAgeRating.general:
        return 'General Audience';
      case VideoAgeRating.mature:
        return 'Mature';
      case VideoAgeRating.adultsOnly:
        return 'Adults Only';
    }
  }

  int get minimumRecommendedAge {
    switch (this) {
      case VideoAgeRating.earlyChildhood:
        return 0;
      case VideoAgeRating.children:
        return 6;
      case VideoAgeRating.preTeen:
        return 10;
      case VideoAgeRating.teen:
        return 13;
      case VideoAgeRating.general:
        return 0;
      case VideoAgeRating.mature:
        return 16;
      case VideoAgeRating.adultsOnly:
        return 18;
    }
  }
}

class MinorContentClassification {
  const MinorContentClassification({
    required this.type,
    required this.ageRating,
    required this.containsIdentifiableMinor,
    required this.guardianConsentRequired,
    required this.guardianConsentVerified,
    required this.creatorVerificationRequired,
    required this.creatorVerificationPassed,
    required this.manualReviewRequired,
    required this.manualReviewPassed,
  });

  final MinorContentType type;
  final VideoAgeRating ageRating;
  final bool containsIdentifiableMinor;
  final bool guardianConsentRequired;
  final bool guardianConsentVerified;
  final bool creatorVerificationRequired;
  final bool creatorVerificationPassed;
  final bool manualReviewRequired;
  final bool manualReviewPassed;

  bool get publicationAllowed {
    if (type == MinorContentType.none) {
      return true;
    }
    if (guardianConsentRequired && !guardianConsentVerified) {
      return false;
    }
    if (creatorVerificationRequired && !creatorVerificationPassed) {
      return false;
    }
    if (manualReviewRequired && !manualReviewPassed) {
      return false;
    }
    return true;
  }
}
