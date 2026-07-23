class YohPalIdentity {
  final String uid;
  final String email;
  final String displayName;
  final String role;
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
}
