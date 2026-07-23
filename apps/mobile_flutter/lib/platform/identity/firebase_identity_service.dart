import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/firebase.dart' as fb;
import 'yohpal_identity.dart';
import 'yohpal_identity_service.dart';

class FirebaseIdentityService implements YohPalIdentityService {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseIdentityService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.tryFirebaseAuth(),
        _firestore = firestore ?? fb.tryFirebaseFirestore();

  @override
  Stream<YohPalIdentity?> watchCurrentIdentity() {
    final auth = _auth;
    if (auth == null) return const Stream.empty();
    return auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return getCurrentIdentity();
    });
  }

  @override
  Future<YohPalIdentity?> getCurrentIdentity() async {
    final auth = _auth;
    final fs = _firestore;
    if (auth == null || fs == null) return null;
    final user = auth.currentUser;
    if (user == null) return null;
    final doc =
        await fs.collection('creatorProfiles').doc(user.uid).get();
    final data = doc.data() ?? {};
    return YohPalIdentity(
      uid: user.uid,
      email: user.email ?? '',
      displayName:
          data['displayName'] as String? ?? user.displayName ?? 'YohPal User',
      role: data['role'] as String? ?? 'user',
      verified: data['verified'] == true,
      creatorId: data['creatorId'] as String?,
      businessId: data['businessId'] as String?,
    );
  }

  @override
  Future<void> signOut() {
    final auth = _auth;
    if (auth == null) return Future.value();
    return auth.signOut();
  }

  @override
  Future<bool> hasRole(String role) async {
    final identity = await getCurrentIdentity();
    return identity?.role == role;
  }
}