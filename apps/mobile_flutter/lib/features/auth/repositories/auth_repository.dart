import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/firebase.dart' as fb;
import '../../../core/result/app_result.dart';
import '../models/app_user.dart';
import '../services/auth_error_mapper.dart';

class AuthRepository {
  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : auth = auth ?? fb.tryFirebaseAuth(),
        firestore = firestore ?? fb.tryFirebaseFirestore(),
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<User?> authStateChanges() => auth?.authStateChanges() ?? const Stream.empty();

  User? get currentUser => auth?.currentUser;

  Future<AppResult<UserCredential>> signIn({
    required String email,
    required String password,
  }) async {
    if (auth == null) return const AppResult.failure('Firebase not available');
    try {
      final credential = await auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AppResult.success(credential);
    } on FirebaseAuthException catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    } catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    }
  }

  Future<AppResult<bool>> sendPasswordReset({required String email}) async {
    if (auth == null) return const AppResult.failure('Firebase not available');
    try {
      await auth!.sendPasswordResetEmail(email: email.trim());
      return const AppResult.success(true);
    } on FirebaseAuthException catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    } catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    }
  }

  Future<AppResult<UserCredential>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (auth == null || firestore == null) return const AppResult.failure('Firebase not available');
    try {
      final credential = await auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(displayName);
      try {
        await credential.user!.sendEmailVerification();
      } catch (_) {}

      final user = AppUser(
        uid: uid,
        email: email.trim(),
        displayName: displayName.trim(),
        photoUrl: '',
        interests: const [],
        createdAt: DateTime.now(),
      );
      await firestore!.collection('users').doc(uid).set(user.toMap());
      await firestore!.collection('creatorProfiles').doc(uid).set({
        'userId': uid,
        'displayName': displayName.trim(),
        'photoUrl': '',
        'followerCount': 0,
        'videoCount': 0,
        'eligibilityScore': 0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return AppResult.success(credential);
    } on FirebaseAuthException catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    } catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    }
  }

  Future<AppResult<UserCredential>> signInWithGoogle() async {
    if (auth == null) return const AppResult.failure('Firebase not available');
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AppResult.failure('');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await auth!.signInWithCredential(credential);
      try {
        await _ensureUserProfile(
          userCredential.user!,
          isNewUser: userCredential.additionalUserInfo?.isNewUser ?? false,
        );
      } catch (_) {}
      return AppResult.success(userCredential);
    } on FirebaseAuthException catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    } catch (e) {
      return AppResult.failure('Google sign-in failed. Please try again.');
    }
  }

  Future<AppResult<UserCredential>> signInWithApple() async {
    if (auth == null) return const AppResult.failure('Firebase not available');
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await auth!.signInWithCredential(oauthCredential);
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      try {
        final appleName = [appleCredential.givenName, appleCredential.familyName]
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .join(' ')
            .trim();
        if (isNewUser && appleName.isNotEmpty) {
          await userCredential.user!.updateDisplayName(appleName);
          await userCredential.user!.reload();
        }

        await _ensureUserProfile(auth?.currentUser ?? userCredential.user!,
            isNewUser: isNewUser);
      } catch (_) {}
      return AppResult.success(userCredential);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AppResult.failure('');
      }
      return AppResult.failure('Apple sign-in failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      return AppResult.failure(AuthErrorMapper.message(e));
    } catch (e) {
      return AppResult.failure('Apple sign-in failed. Please try again.');
    }
  }

  Future<void> _ensureUserProfile(User user, {required bool isNewUser}) async {
    if (!isNewUser || firestore == null) return;

    final displayName = user.displayName ?? '';
    final appUser = AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      photoUrl: user.photoURL ?? '',
      interests: const [],
      createdAt: DateTime.now(),
    );
    await firestore!.collection('users').doc(user.uid).set(appUser.toMap());
    await firestore!.collection('creatorProfiles').doc(user.uid).set({
      'userId': user.uid,
      'displayName': displayName,
      'photoUrl': user.photoURL ?? '',
      'followerCount': 0,
      'videoCount': 0,
      'eligibilityScore': 0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await auth?.signOut();
  }
}
