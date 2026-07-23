enum MinorCreatorVerificationStatus {
  notRequired,
  pending,
  documentSubmitted,
  approved,
  rejected,
  suspended,
}

extension MinorCreatorVerificationStatusLabel on MinorCreatorVerificationStatus {
  String get label {
    switch (this) {
      case MinorCreatorVerificationStatus.notRequired:
        return 'Not Required';
      case MinorCreatorVerificationStatus.pending:
        return 'Pending';
      case MinorCreatorVerificationStatus.documentSubmitted:
        return 'Under Review';
      case MinorCreatorVerificationStatus.approved:
        return 'Approved';
      case MinorCreatorVerificationStatus.rejected:
        return 'Rejected';
      case MinorCreatorVerificationStatus.suspended:
        return 'Suspended';
    }
  }

  bool get allowsPublication => this == MinorCreatorVerificationStatus.approved ||
      this == MinorCreatorVerificationStatus.notRequired;
}

class MinorCreatorVerification {
  const MinorCreatorVerification({
    required this.creatorUid,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.reviewerUid,
    this.rejectionReason,
    this.guardianUid,
    this.dateOfBirth,
    this.advertisingAllowed = false,
    this.directMessagingAllowed = false,
    this.duetAllowed = false,
  });

  final String creatorUid;
  final MinorCreatorVerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewerUid;
  final String? rejectionReason;
  final String? guardianUid;
  final DateTime? dateOfBirth;
  final bool advertisingAllowed;
  final bool directMessagingAllowed;
  final bool duetAllowed;

  int? get ageInYears {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isMinor {
    final age = ageInYears;
    return age != null && age < 18;
  }

  bool get isApproved => status == MinorCreatorVerificationStatus.approved;

  factory MinorCreatorVerification.fromMap(Map<String, dynamic> map) {
    return MinorCreatorVerification(
      creatorUid: map['creatorUid'] as String? ?? '',
      status: _statusFromString(map['status'] as String? ?? ''),
      submittedAt: map['submittedAt'] != null
          ? DateTime.tryParse(map['submittedAt'].toString())
          : null,
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
      reviewerUid: map['reviewerUid'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      guardianUid: map['guardianUid'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString())
          : null,
      advertisingAllowed: map['advertisingAllowed'] as bool? ?? false,
      directMessagingAllowed: map['directMessagingAllowed'] as bool? ?? false,
      duetAllowed: map['duetAllowed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'creatorUid': creatorUid,
        'status': status.name,
        'submittedAt': submittedAt?.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewerUid': reviewerUid,
        'rejectionReason': rejectionReason,
        'guardianUid': guardianUid,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'advertisingAllowed': advertisingAllowed,
        'directMessagingAllowed': directMessagingAllowed,
        'duetAllowed': duetAllowed,
      };

  static MinorCreatorVerificationStatus _statusFromString(String s) {
    return MinorCreatorVerificationStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => MinorCreatorVerificationStatus.notRequired,
    );
  }

  MinorCreatorVerification copyWith({
    MinorCreatorVerificationStatus? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewerUid,
    String? rejectionReason,
    String? guardianUid,
    DateTime? dateOfBirth,
    bool? advertisingAllowed,
    bool? directMessagingAllowed,
    bool? duetAllowed,
  }) =>
      MinorCreatorVerification(
        creatorUid: creatorUid,
        status: status ?? this.status,
        submittedAt: submittedAt ?? this.submittedAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        reviewerUid: reviewerUid ?? this.reviewerUid,
        rejectionReason: rejectionReason ?? this.rejectionReason,
        guardianUid: guardianUid ?? this.guardianUid,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        advertisingAllowed: advertisingAllowed ?? this.advertisingAllowed,
        directMessagingAllowed:
            directMessagingAllowed ?? this.directMessagingAllowed,
        duetAllowed: duetAllowed ?? this.duetAllowed,
      );
}
