// lib/features/auth/presentation/bloc/auth_state.dart

import 'package:habitiurs/core/auth/models/user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuthenticated && 
      runtimeType == other.runtimeType &&
      user == other.user;

  @override
  int get hashCode => user.hashCode;
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthError && 
      runtimeType == other.runtimeType &&
      message == other.message;

  @override
  int get hashCode => message.hashCode;
}