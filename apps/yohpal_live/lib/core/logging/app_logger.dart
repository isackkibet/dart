import 'dart:developer' as developer;

class AppLogger {
  const AppLogger._();

  static void info(String message, {Object? data}) {
    developer.log(
      message,
      name: 'YohPal.Info',
      error: data,
    );
  }

  static void warning(String message, {Object? data}) {
    developer.log(
      message,
      name: 'YohPal.Warning',
      error: data,
      level: 900,
    );
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'YohPal.Error',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
