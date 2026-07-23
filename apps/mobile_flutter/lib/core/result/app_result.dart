class AppResult<T> {
  final T? data;
  final String? error;

  const AppResult.success(this.data) : error = null;
  const AppResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
}
