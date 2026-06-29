// lib/core/auth/models/auth_result.dart
import 'package:habitiurs/core/auth/exceptions/auth_exceptions.dart';

/// Result types para operaciones de autenticación
abstract class AuthResult<T> {
  const AuthResult();
}

class AuthSuccess<T> extends AuthResult<T> {
  final T data;
  const AuthSuccess(this.data);
}

class AuthFailure<T> extends AuthResult<T> {
  final AuthException exception;
  const AuthFailure(this.exception);
}
