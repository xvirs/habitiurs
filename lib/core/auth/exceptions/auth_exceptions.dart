// lib/core/auth/exceptions/auth_exceptions.dart
abstract class AuthException implements Exception {
  final String message;
  final String? code;
  
  const AuthException(this.message, {this.code});
  
  @override
  String toString() => 'AuthException: $message';
}

class LoginCancelledException extends AuthException {
  const LoginCancelledException() : super('Login cancelado por el usuario');
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Credenciales inválidas');
}

class NetworkAuthException extends AuthException {
  const NetworkAuthException() : super('Error de conexión durante autenticación');
}

class UnknownAuthException extends AuthException {
  const UnknownAuthException(String message) : super(message);
}
