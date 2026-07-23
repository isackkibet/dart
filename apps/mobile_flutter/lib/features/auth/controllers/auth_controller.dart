import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../../core/result/app_result.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_error_mapper.dart';
import '../session_cleanup_service.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository repository;

  // Assigned once, after the provider tree exists — see app.dart. Nullable
  // because AuthController is constructed before the controllers it needs
  // to clear are available.
  YohPalSessionCleanupService? sessionCleanupService;

  User? user;
  bool loading = false;
  String? error;

  bool authReady = false;

  AuthController({required this.repository}) {
    repository.authStateChanges().listen((firebaseUser) {
      user = firebaseUser;
      authReady = true;
      try { FirebaseCrashlytics.instance.setUserIdentifier(firebaseUser?.uid ?? ''); } catch (_) {}
      notifyListeners();
    });
  }

  bool get isAuthenticated => user != null;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    final result = await repository.signIn(email: email, password: password);
    loading = false;
    if (!result.isSuccess) {
      error = AuthErrorMapper.message(result.error ?? 'Login failed');
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    final result = await repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    loading = false;
    if (!result.isSuccess) {
      error = AuthErrorMapper.message(result.error ?? 'Signup failed');
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> sendPasswordReset({required String email}) async {
    loading = true;
    error = null;
    notifyListeners();
    final result = await repository.sendPasswordReset(email: email);
    loading = false;
    if (!result.isSuccess) {
      error = AuthErrorMapper.message(result.error ?? 'Reset failed');
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<bool> loginWithGoogle() => _loginWithSso(repository.signInWithGoogle);

  Future<bool> loginWithApple() => _loginWithSso(repository.signInWithApple);

  /// Shared by loginWithGoogle/loginWithApple — same loading/error contract
  /// as login()/signup(), except a user dismissing the account picker or
  /// Apple sheet comes back as an empty-string error (see AuthRepository)
  /// and is treated as a silent no-op rather than shown as a failure.
  Future<bool> _loginWithSso(
    Future<AppResult<UserCredential>> Function() signIn,
  ) async {
    loading = true;
    error = null;
    notifyListeners();

    final result = await signIn();

    loading = false;
    if (!result.isSuccess) {
      if (result.error?.isNotEmpty ?? false) {
        error = result.error;
      }
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      await sessionCleanupService?.clearAll();
    } catch (_) {
      // Best-effort — cache cleanup failing must never block the actual
      // sign-out, which is the security-critical half of logout.
    }
    await repository.signOut();
  }
}
