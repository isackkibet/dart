import 'yohpal_user_role.dart';

class YohPalAuthUser {
  const YohPalAuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.claims,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final YohPalUserRole role;
  final Map<String, dynamic> claims;

  bool get isAdmin => role.isAdmin;
  bool get isCreator => role == YohPalUserRole.creator || isAdmin;

  factory YohPalAuthUser.fromFirebaseClaims({
    required String uid,
    String? email,
    String? displayName,
    required Map<String, dynamic> claims,
  }) {
    final rawRole = claims['role']?.toString();
    final fallbackRole = claims['admin'] == true
        ? YohPalUserRole.admin
        : claims['creator'] == true
            ? YohPalUserRole.creator
            : YohPalUserRole.viewer;
    return YohPalAuthUser(
      uid: uid,
      email: email,
      displayName: displayName,
      role: rawRole == null ? fallbackRole : YohPalUserRole.fromString(rawRole),
      claims: claims,
    );
  }
}
