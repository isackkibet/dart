import 'dart:async';
import 'package:flutter/foundation.dart';
import '../errors/app_failure.dart';
import '../models/result.dart';
import 'yohpal_auth_service.dart';
import 'yohpal_auth_user.dart';

class YohPalAuthController extends ChangeNotifier {
  YohPalAuthController({
    required YohPalAuthService authService,
  }) : _authService = authService;

  final YohPalAuthService _authService;
  StreamSubscription<YohPalAuthUser?>? _subscription;
  YohPalAuthUser? _user;
  bool _isLoading = true;
  AppFailure? _lastFailure;

  YohPalAuthUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  AppFailure? get lastFailure => _lastFailure;

  void start() {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();
    _subscription = _authService.authStateChanges().listen(
      (user) {
        _user = user;
        _isLoading = false;
        _lastFailure = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _lastFailure = AppFailure(
          message: 'Authentication state failed.',
          code: 'auth_state_error',
          details: error,
        );
        notifyListeners();
      },
    );
  }

  Future<Result<YohPalAuthUser>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _lastFailure = null;
    notifyListeners();
    final result = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _isLoading = false;
    if (result is Success<YohPalAuthUser>) {
      _user = result.data;
    } else if (result is Failure<YohPalAuthUser>) {
      _lastFailure = result.failure;
    }
    notifyListeners();
    return result;
  }

  Future<Result<YohPalAuthUser>> signup({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _lastFailure = null;
    notifyListeners();
    final result = await _authService.createAccount(
      email: email,
      password: password,
      displayName: displayName,
    );
    _isLoading = false;
    if (result is Success<YohPalAuthUser>) {
      _user = result.data;
    } else if (result is Failure<YohPalAuthUser>) {
      _lastFailure = result.failure;
    }
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshClaims() async {
    if (_user == null) return;
    _user = await _authService.refreshClaims();
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
