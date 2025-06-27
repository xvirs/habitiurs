import '../exceptions/auth_exceptions.dart';
import '../../common/models/result.dart';

/// Type alias for authentication results
typedef AuthResult<T> = Result<T>;

/// Extensions for AuthResult
extension AuthResultExtensions<T> on AuthResult<T> {
  /// Create success result
  static AuthResult<T> success<T>(T data) => Success(data);
  
  /// Create failure result
  static AuthResult<T> failure<T>(AuthException exception) => Failure(exception);
  
  /// Get the auth exception if this is a failure
  AuthException? get authException => switch (this) {
    Success() => null,
    Failure(exception: final exception) when exception is AuthException => 
        exception,
    Failure(exception: final exception) => 
        UnknownAuthException(exception.toString()),
  };
}