import 'package:firebase_core/firebase_core.dart';
import '../logging/app_logger.dart';

class YohPalFirebaseBootstrap {
  const YohPalFirebaseBootstrap._();

  static Future<void> initialize({
    FirebaseOptions? options,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      AppLogger.info('Firebase initialized successfully.');
    } catch (error, stackTrace) {
      AppLogger.error(
        'Firebase initialization failed.',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
