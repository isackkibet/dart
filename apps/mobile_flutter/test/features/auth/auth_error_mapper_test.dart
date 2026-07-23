import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yohpal_live_v2/features/auth/services/auth_error_mapper.dart';

void main() {
  group('AuthErrorMapper', () {
    test('maps invalid-credential to friendly copy', () {
      expect(
        AuthErrorMapper.message(
          FirebaseAuthException(code: 'invalid-credential'),
        ),
        'The email or password is incorrect.',
      );
    });

    test('maps wrong-password to the same friendly copy', () {
      expect(
        AuthErrorMapper.message(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        'The email or password is incorrect.',
      );
    });

    test('maps user-not-found', () {
      expect(
        AuthErrorMapper.message(FirebaseAuthException(code: 'user-not-found')),
        'No account exists for that email.',
      );
    });

    test('maps email-already-in-use', () {
      expect(
        AuthErrorMapper.message(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        'An account already exists for that email.',
      );
    });

    test('falls back to a generic message for unknown codes', () {
      expect(
        AuthErrorMapper.message(
          FirebaseAuthException(code: 'some-unmapped-code'),
        ),
        'We could not complete that request. Please try again.',
      );
    });

    test('never surfaces the raw Firebase error code or message', () {
      final message = AuthErrorMapper.message(
        FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The supplied auth credential is malformed or expired.',
        ),
      );
      expect(message, isNot(contains('firebase_auth')));
      expect(message, isNot(contains('invalid-credential')));
    });

    test('handles non-FirebaseAuthException errors', () {
      expect(
        AuthErrorMapper.message(Exception('network down')),
        'Something went wrong. Please try again.',
      );
    });
  });
}
