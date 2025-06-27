abstract class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, {this.code});
  
  @override
  String toString() => 'AuthException: $message';
}

class LoginCancelledException extends AuthException {
  const LoginCancelledException() : super('Login cancelled by user');
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid credentials');
}

class NetworkAuthException extends AuthException {
  const NetworkAuthException() : super('Network error during authentication');
}

class UserDisabledException extends AuthException {
  const UserDisabledException() : super('This account has been disabled');
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException() : super('Too many attempts. Please wait a moment.');
}

class ServiceUnavailableException extends AuthException {
  const ServiceUnavailableException(String service) : super('$service service not available');
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException(String message) : super(message);
}