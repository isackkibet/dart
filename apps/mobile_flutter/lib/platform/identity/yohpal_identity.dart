class YohPalIdentity {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'viewer' | 'creator' | 'business' | 'admin'
  final bool verified;
  final String? creatorId;
  final String? businessId;

  const YohPalIdentity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.verified = false,
    this.creatorId,
    this.businessId,
  });

  factory YohPalIdentity.fromMap(String uid, Map<String, dynamic> data) {
    return YohPalIdentity(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'viewer',
      verified: data['verified'] == true,
      creatorId: data['creatorId'] as String?,
      businessId: data['businessId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'role': role,
        'verified': verified,
        if (creatorId != null) 'creatorId': creatorId,
        if (businessId != null) 'businessId': businessId,
      };
}
