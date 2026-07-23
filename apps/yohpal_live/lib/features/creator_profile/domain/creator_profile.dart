class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.handle,
    required this.category,
    required this.bio,
    required this.verificationStatus,
    required this.monetisationEnabled,
    required this.riskScore,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String uid;
  final String displayName;
  final String handle;
  final String category;
  final String bio;
  final String verificationStatus;
  final bool monetisationEnabled;
  final double riskScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CreatorProfile.fromMap(String id, Map<String, dynamic> map) {
    return CreatorProfile(
      id: id,
      uid: map['uid']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      handle: map['handle']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      bio: map['bio']?.toString() ?? '',
      verificationStatus: map['verificationStatus']?.toString() ?? 'pending',
      monetisationEnabled: map['monetisationEnabled'] == true,
      riskScore: (map['riskScore'] as num?)?.toDouble() ?? 0,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'handle': handle,
      'category': category,
      'bio': bio,
      'verificationStatus': verificationStatus,
      'monetisationEnabled': monetisationEnabled,
      'riskScore': riskScore,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
