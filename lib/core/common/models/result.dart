sealed class Result<T> {
  const Result();
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  T get data => switch (this) {
    Success(data: final data) => data,
    Failure() => throw StateError('Cannot get data from failure result'),
  };
  
  Exception get error => switch (this) {
    Success() => throw StateError('Cannot get error from success result'),
    Failure(exception: final error) => error,
  };
  
  Result<U> map<U>(U Function(T) transform) => switch (this) {
    Success(data: final data) => Success(transform(data)),
    Failure(exception: final error) => Failure(error),
  };
  
  U fold<U>(
    U Function(T) onSuccess,
    U Function(Exception) onFailure,
  ) => switch (this) {
    Success(data: final data) => onSuccess(data),
    Failure(exception: final error) => onFailure(error),
  };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;
  
  @override
  int get hashCode => data.hashCode;
}

final class Failure<T> extends Result<T> {
  final Exception exception;
  const Failure(this.exception);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && exception == other.exception;
  
  @override
  int get hashCode => exception.hashCode;
}