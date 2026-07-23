class ImportedContactModel {
  final String id;
  final String ownerUserId;
  final String name;
  final String phone;
  final String normalizedPhone;
  final bool existingYohPalUser;
  final String? matchedUserId;
  final int inviteScore;
  final DateTime importedAt;

  const ImportedContactModel({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.phone,
    required this.normalizedPhone,
    required this.existingYohPalUser,
    this.matchedUserId,
    required this.inviteScore,
    required this.importedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerUserId': ownerUserId,
      'name': name,
      'phone': phone,
      'normalizedPhone': normalizedPhone,
      'existingYohPalUser': existingYohPalUser,
      'matchedUserId': matchedUserId,
      'inviteScore': inviteScore,
      'importedAt': importedAt.toIso8601String(),
    };
  }
}
