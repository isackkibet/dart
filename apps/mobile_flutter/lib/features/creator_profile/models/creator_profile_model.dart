class CreatorProfileModel {
  final String userId;
  final String username;
  final String displayName;
  final String bio;
  final String photoUrl;
  final int followerCount;
  final int videoCount;
  final int eligibilityScore;
  final String status;

  const CreatorProfileModel({
    required this.userId,
    this.username = '',
    required this.displayName,
    required this.bio,
    required this.photoUrl,
    required this.followerCount,
    required this.videoCount,
    required this.eligibilityScore,
    required this.status,
  });

  factory CreatorProfileModel.fromMap(Map<String, dynamic> map) {
    return CreatorProfileModel(
      userId: map['userId'] ?? '',
      username: map['username'] as String? ?? map['userName'] as String? ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      followerCount: (map['followerCount'] as num? ?? 0).toInt(),
      videoCount: (map['videoCount'] as num? ?? 0).toInt(),
      eligibilityScore: (map['eligibilityScore'] as num? ?? 0).toInt(),
      status: map['status'] ?? 'active',
    );
  }

  factory CreatorProfileModel.fromUserMap(String uid, Map<String, dynamic> map) {
    final first = map['firstName'] as String? ?? '';
    final last = map['lastName'] as String? ?? '';
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    final uname = map['userName'] as String? ?? map['username'] as String? ?? '';
    return CreatorProfileModel(
      userId: uid,
      username: uname,
      displayName: fullName.isNotEmpty ? fullName : uname,
      bio: map['bio'] as String? ?? '',
      photoUrl: map['profile_picture'] as String? ?? '',
      followerCount: (map['followersCount'] as num? ?? 0).toInt(),
      videoCount: 0,
      eligibilityScore: 0,
      status: map['status'] as String? ?? 'active',
    );
  }

  static Map<String, dynamic> displayFieldsFromUserMap(Map<String, dynamic> map) {
    final first = map['firstName'] as String? ?? '';
    final last = map['lastName'] as String? ?? '';
    final fullName = [first, last].where((s) => s.isNotEmpty).join(' ');
    final uname = map['userName'] as String? ?? map['username'] as String? ?? '';
    return {
      'displayName': fullName.isNotEmpty ? fullName : uname,
      'username':    uname,
      'photoUrl':    map['profile_picture'] as String? ?? '',
      'bio':         map['bio'] as String? ?? '',
    };
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'username': username,
        'displayName': displayName,
        'bio': bio,
        'photoUrl': photoUrl,
        'followerCount': followerCount,
        'videoCount': videoCount,
        'eligibilityScore': eligibilityScore,
        'status': status,
      };
}
