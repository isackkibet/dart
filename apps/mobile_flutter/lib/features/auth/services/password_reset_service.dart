import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/firebase.dart' as fb;

final class PasswordResetService {
  PasswordResetService({FirebaseAuth? auth})
      : _auth = auth ?? fb.tryFirebaseAuth();

  final FirebaseAuth? _auth;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> sendResetEmail(String rawEmail) async {
    final auth = _auth;
    if (auth == null) throw StateError('Firebase not initialized');
    final email = rawEmail.trim();
    if (!_emailPattern.hasMatch(email)) {
      throw const FormatException('Enter a valid email address.');
    }
    await auth.sendPasswordResetEmail(email: email);
  }
}