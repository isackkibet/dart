import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'yohpal_identity.dart';
import 'yohpal_identity_service.dart';

class FirebaseIdentityService implements YohPalIdentityService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  FirebaseIdentityService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;
  @override
  Stream<YohPalIdentity?> watchCurrentIdentity() {
    return auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getCurrentIdentity();
    });
  }
  @override
  Future<YohPalIdentity?> getCurrentIdentity() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final doc =
        await firestore.collection('creatorProfiles').doc(user.uid).get();
    final data = doc.data() ?? {};
    return YohPalIdentity(
      uid: user.uid,
      email: user.email ?? '',
      displayName: data['displayName'] ?? user.displayName ?? 'YohPal User',
      role: data['role'] ?? 'user',
      verified: data['verified'] == true,
      creatorId: data['creatorId'],
      businessId: data['businessId'],
    );
  }
  @override
  Future<void> signOut() => auth.signOut();
  @override
  Future<bool> hasRole(String role) async {
    final identity = await getCurrentIdentity();
    return identity?.role == role;
  }
}
