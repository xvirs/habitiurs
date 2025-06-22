// lib/features/auth/presentation/bloc/auth_event.dart
import 'package:habitiurs/core/auth/models/user.dart';

abstract class AuthEvent {}

class AuthInitializationRequested extends AuthEvent {}

class AuthLoginWithGoogleRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthGuestModeRequested extends AuthEvent {}

class AuthUserChanged extends AuthEvent {
  final User? user;
  AuthUserChanged(this.user);
}