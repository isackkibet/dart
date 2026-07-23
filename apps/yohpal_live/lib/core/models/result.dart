import '../errors/app_failure.dart';

sealed class Result<T> {
  const Result();
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull {
    final current = this;
    if (current is Success<T>) return current.data;
    return null;
  }

  AppFailure? get failureOrNull {
    final current = this;
    if (current is Failure<T>) return current.failure;
    return null;
  }
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}
