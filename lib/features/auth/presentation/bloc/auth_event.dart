// lib/features/auth/presentation/bloc/auth_event.dart
import 'package:equatable/equatable.dart';
import '../../../../core/auth/models/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class AuthInitializationRequested extends AuthEvent {}

class AuthLoginWithGoogleRequested extends AuthEvent {}

class AuthLoginWithAppleRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthGuestSessionRequested extends AuthEvent {}

class AuthStatusChanged extends AuthEvent {
  final User? user;
  const AuthStatusChanged(this.user);

  @override
  List<Object> get props => [user ?? Object()];
}
