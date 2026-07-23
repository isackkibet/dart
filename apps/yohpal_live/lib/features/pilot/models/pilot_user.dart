class PilotUser {
  final String uid;
  final String email;
  final String role;
  const PilotUser({
    required this.uid,
    required this.email,
    required this.role,
  });
  factory PilotUser.fromMap(Map<String, dynamic> json) {
    return PilotUser(
      uid: json['uid'],
      email: json['email'],
      role: json['role'],
    );
  }
}
