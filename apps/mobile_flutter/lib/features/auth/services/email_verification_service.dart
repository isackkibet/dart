import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/firebase.dart' as fb;

final class EmailVerificationService {
  EmailVerificationService({FirebaseAuth? auth})
      : _auth = auth ?? fb.tryFirebaseAuth();

  final FirebaseAuth? _auth;

  Future<void> sendVerification() async {
    final auth = _auth;
    if (auth == null) throw StateError('Firebase not initialized');
    final user = auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheck() async {
    final auth = _auth;
    if (auth == null) return false;
    await auth.currentUser?.reload();
    return auth.currentUser?.emailVerified ?? false;
  }
}