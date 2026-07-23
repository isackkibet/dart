import 'package:firebase_auth/firebase_auth.dart';

/// Maps raw FirebaseAuthException codes to copy a user can act on, instead of
/// the technical '[code] message' strings AuthRepository used to surface
/// directly in the login/signup UI.
final class AuthErrorMapper {
  const AuthErrorMapper._();

  static String message(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' ||
        'wrong-password' =>
          'The email or password is incorrect.',
        'user-not-found' => 'No account exists for that email.',
        'email-already-in-use' => 'An account already exists for that email.',
        'weak-password' =>
          'Use a stronger password with at least eight characters.',
        'too-many-requests' => 'Too many attempts. Wait briefly and try again.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'user-disabled' => 'This account has been disabled. Contact support.',
        _ => 'We could not complete that request. Please try again.',
      };
    }
    return 'Something went wrong. Please try again.';
  }
}
