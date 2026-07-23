import 'package:firebase_auth/firebase_auth.dart';
import '../errors/app_failure.dart';
import '../models/result.dart';
import 'yohpal_auth_user.dart';
import 'yohpal_user_role.dart';

class YohPalAuthService {
  YohPalAuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<YohPalAuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _mapFirebaseUser(user, forceRefresh: false);
    });
  }

  String? get currentUserId => currentUser?.uid;
  String? get currentUserName => currentUser?.displayName;

  YohPalAuthUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return YohPalAuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      role: YohPalUserRole.viewer,
      claims: const {},
    );
  }

  Future<Result<YohPalAuthUser>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Failure(
          AppFailure(
            message: 'Login failed. No user returned.',
            code: 'auth_no_user',
          ),
        );
      }
      final mapped = await _mapFirebaseUser(user, forceRefresh: true);
      return Success(mapped);
    } on FirebaseAuthException catch (error) {
      return Failure(
        AppFailure(
          message: _firebaseAuthMessage(error),
          code: error.code,
          details: error.message,
        ),
      );
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Login failed.',
          code: 'auth_login_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<YohPalAuthUser>> createAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Failure(
          AppFailure(
            message: 'Signup failed. No user returned.',
            code: 'auth_no_user',
          ),
        );
      }
      await user.updateDisplayName(displayName.trim());
      await user.reload();
      final refreshed = _firebaseAuth.currentUser ?? user;
      final mapped = await _mapFirebaseUser(refreshed, forceRefresh: true);
      return Success(mapped);
    } on FirebaseAuthException catch (error) {
      return Failure(
        AppFailure(
          message: _firebaseAuthMessage(error),
          code: error.code,
          details: error.message,
        ),
      );
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Signup failed.',
          code: 'auth_signup_failed',
          details: error,
        ),
      );
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Success(null);
    } catch (error) {
      return Failure(
        AppFailure(
          message: 'Logout failed.',
          code: 'auth_logout_failed',
          details: error,
        ),
      );
    }
  }

  Future<String?> getIdToken([bool forceRefresh = false]) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  Future<YohPalAuthUser> refreshClaims() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }
    return _mapFirebaseUser(user, forceRefresh: true);
  }

  Future<YohPalAuthUser> _mapFirebaseUser(
    User user, {
    required bool forceRefresh,
  }) async {
    final token = await user.getIdTokenResult(forceRefresh);
    final claims = Map<String, dynamic>.from(token.claims ?? {});
    return YohPalAuthUser.fromFirebaseClaims(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      claims: claims,
    );
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    return switch (error.code) {
      'user-not-found' => 'No account was found for this email.',
      'wrong-password' => 'The password is incorrect.',
      'invalid-email' => 'The email address is invalid.',
      'email-already-in-use' => 'This email is already registered.',
      'weak-password' => 'The password is too weak.',
      'network-request-failed' => 'Network error. Check your connection.',
      _ => error.message ?? 'Authentication failed.',
    };
  }
}
