import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'app/app.dart';
import 'core/deep_links/yohpal_deep_link_service.dart';
import 'core/diagnostics/app_start_clock.dart';
import 'core/observability/yohpal_crash_reporter.dart';
import 'firebase_options.dart';
import 'features/notifications/firebase_background_handler.dart';

Future<void> main() async {
  // ignore: unnecessary_statements
  appStartTime;
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    debugPrint('Firebase init skipped for this platform.');
  }

  final crashReporter = FirebaseYohPalCrashReporter(
    crashlytics: firebaseReady ? FirebaseCrashlytics.instance : null,
  );

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(crashReporter.recordFlutterError(details));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      crashReporter.recordError(
        error,
        stack,
        fatal: true,
        reason: 'PlatformDispatcher uncaught error',
      ),
    );
    return true;
  };

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  YohPalDeepLinkService().start(rootNavigatorKey);

  runApp(
    Builder(builder: (_) => const YohPalLiveApp()),
  );
}

