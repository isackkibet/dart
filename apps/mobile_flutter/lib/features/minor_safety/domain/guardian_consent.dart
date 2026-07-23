enum GuardianConsentStatus {
  notRequested,
  pending,
  approved,
  denied,
  revoked,
  expired,
}

extension GuardianConsentStatusLabel on GuardianConsentStatus {
  String get label {
    switch (this) {
      case GuardianConsentStatus.notRequested:
        return 'Not Requested';
      case GuardianConsentStatus.pending:
        return 'Awaiting Guardian';
      case GuardianConsentStatus.approved:
        return 'Approved';
      case GuardianConsentStatus.denied:
        return 'Denied';
      case GuardianConsentStatus.revoked:
        return 'Revoked';
      case GuardianConsentStatus.expired:
        return 'Expired';
    }
  }

  bool get isActive => this == GuardianConsentStatus.approved;
}

enum GuardianConsentScope {
  accountCreation,
  contentPublication,
  advertising,
  directMessages,
  duet,
  liveStreaming,
}

class GuardianConsent {
  const GuardianConsent({
    required this.consentId,
    required this.minorUid,
    required this.guardianUid,
    required this.status,
    required this.scope,
    required this.requestedAt,
    this.respondedAt,
    this.expiresAt,
    this.ipAddress,
    this.userAgent,
    this.notes,
  });

  final String consentId;
  final String minorUid;
  final String guardianUid;
  final GuardianConsentStatus status;
  final List<GuardianConsentScope> scope;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final String? ipAddress;
  final String? userAgent;
  final String? notes;

  bool get isValid {
    if (status != GuardianConsentStatus.approved) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  bool coversScope(GuardianConsentScope requiredScope) =>
      isValid && scope.contains(requiredScope);

  factory GuardianConsent.fromMap(Map<String, dynamic> map) {
    return GuardianConsent(
      consentId: map['consentId'] as String? ?? '',
      minorUid: map['minorUid'] as String? ?? '',
      guardianUid: map['guardianUid'] as String? ?? '',
      status: _statusFromString(map['status'] as String? ?? ''),
      scope: _scopeListFromStrings(
          (map['scope'] as List<dynamic>?)?.cast<String>() ?? []),
      requestedAt: map['requestedAt'] != null
          ? DateTime.parse(map['requestedAt'].toString())
          : DateTime.now(),
      respondedAt: map['respondedAt'] != null
          ? DateTime.tryParse(map['respondedAt'].toString())
          : null,
      expiresAt: map['expiresAt'] != null
          ? DateTime.tryParse(map['expiresAt'].toString())
          : null,
      ipAddress: map['ipAddress'] as String?,
      userAgent: map['userAgent'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'consentId': consentId,
        'minorUid': minorUid,
        'guardianUid': guardianUid,
        'status': status.name,
        'scope': scope.map((s) => s.name).toList(),
        'requestedAt': requestedAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'notes': notes,
      };

  static GuardianConsentStatus _statusFromString(String s) {
    return GuardianConsentStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => GuardianConsentStatus.notRequested,
    );
  }

  static List<GuardianConsentScope> _scopeListFromStrings(
      List<String> strings) {
    return strings
        .map((s) => GuardianConsentScope.values.firstWhere(
              (e) => e.name == s,
              orElse: () => GuardianConsentScope.contentPublication,
            ))
        .toList();
  }

  GuardianConsent copyWith({
    GuardianConsentStatus? status,
    List<GuardianConsentScope>? scope,
    DateTime? respondedAt,
    DateTime? expiresAt,
    String? notes,
  }) =>
      GuardianConsent(
        consentId: consentId,
        minorUid: minorUid,
        guardianUid: guardianUid,
        status: status ?? this.status,
        scope: scope ?? this.scope,
        requestedAt: requestedAt,
        respondedAt: respondedAt ?? this.respondedAt,
        expiresAt: expiresAt ?? this.expiresAt,
        ipAddress: ipAddress,
        userAgent: userAgent,
        notes: notes ?? this.notes,
      );
}
