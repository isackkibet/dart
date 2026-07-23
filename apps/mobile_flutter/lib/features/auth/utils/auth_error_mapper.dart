class AuthErrorMapper {
  AuthErrorMapper._();

  static String map(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('user-not-found') || s.contains('invalid-credential')) {
      return 'Email or password is incorrect.';
    }
    if (s.contains('wrong-password')) {
      return 'Incorrect password. Try again or reset it below.';
    }
    if (s.contains('email-already-in-use')) {
      return 'An account with that email already exists.';
    }
    if (s.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    if (s.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (s.contains('too-many-requests') || s.contains('quota-exceeded')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (s.contains('network-request-failed') || s.contains('network')) {
      return 'No internet connection. Check your network and try again.';
    }
    if (s.contains('user-disabled')) {
      return 'This account has been disabled. Contact support.';
    }
    return raw;
  }
}
