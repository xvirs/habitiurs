// lib/features/auth/presentation/bloc/auth_state.dart

import 'package:habitiurs/core/auth/models/user.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  AuthLoading({this.message});
}

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
  final String? technicalDetails; // Make it nullable

  AuthError(this.message, {this.technicalDetails}); // Add the named parameter

  List<Object?> get props => [message, technicalDetails];
}