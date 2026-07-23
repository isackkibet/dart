import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract interface class YohPalCrashReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  });

  Future<void> recordFlutterError(FlutterErrorDetails details);

  Future<void> setUserId(String? uid);

  Future<void> log(String message);
}

final class FirebaseYohPalCrashReporter implements YohPalCrashReporter {
  FirebaseYohPalCrashReporter({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics;

  final FirebaseCrashlytics? _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    String? reason,
  }) {
    if (_crashlytics == null) return Future.value();
    return _crashlytics.recordError(
      error,
      stackTrace,
      fatal: fatal,
      reason: reason,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return _crashlytics?.recordFlutterFatalError(details) ?? Future.value();
  }

  @override
  Future<void> setUserId(String? uid) {
    return _crashlytics?.setUserIdentifier(uid ?? '') ?? Future.value();
  }

  @override
  Future<void> log(String message) {
    return _crashlytics?.log(message) ?? Future.value();
  }
}
