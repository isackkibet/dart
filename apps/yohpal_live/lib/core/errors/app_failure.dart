class AppFailure implements Exception {
  const AppFailure({required this.message, this.code, this.details});

  final String message;
  final String? code;
  final Object? details;

  @override
  String toString() =>
      'AppFailure(message: $message, code: $code, details: $details)';
}
