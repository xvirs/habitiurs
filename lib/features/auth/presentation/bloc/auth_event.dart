// lib/features/auth/presentation/bloc/auth_event.dart - NUEVO
abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthSkipRequested extends AuthEvent {}

