import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/core/auth/models/auth_result.dart';
import 'package:habitiurs/core/auth/models/user.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/create_guest_session.dart';
import '../../domain/usecases/check_auth_status.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithGoogle _loginWithGoogle;
  final LogoutUser _logoutUser;
  final CreateGuestSession _createGuestSession;
  final CheckAuthStatus _checkAuthStatus;
  
  late StreamSubscription<User?> _authStateSubscription;

  AuthBloc({
    required LoginWithGoogle loginWithGoogle,
    required LogoutUser logoutUser,
    required CreateGuestSession createGuestSession,
    required CheckAuthStatus checkAuthStatus,
  }) : _loginWithGoogle = loginWithGoogle,
       _logoutUser = logoutUser,
       _createGuestSession = createGuestSession,
       _checkAuthStatus = checkAuthStatus,
       super(AuthInitial()) {
    
    on<AuthInitializationRequested>(_onInitializationRequested);
    on<AuthLoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthGuestModeRequested>(_onGuestModeRequested);
    on<AuthUserChanged>(_onUserChanged);
    
    // Escuchar cambios de estado de auth
    _authStateSubscription = _checkAuthStatus().listen((user) {
      print('### AuthBloc: Recibido evento de stream authStateChanges. User: ${user?.email ?? 'null'}'); // DEBUG LOG
      add(AuthUserChanged(user as User?));
    });
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    print('### AuthBloc: StreamSubscription de authStateChanges cancelado.'); // DEBUG LOG
    return super.close();
  }

  Future<void> _onInitializationRequested(
    AuthInitializationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('### AuthBloc: Recibido AuthInitializationRequested. Emitiendo AuthLoading.'); // DEBUG LOG
    
    // Simular splash screen
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final currentUser = _checkAuthStatus.getCurrentUser();
    if (currentUser != null) {
      print('### AuthBloc: Usuario actual encontrado al inicializar: ${currentUser.email}. Emitiendo AuthAuthenticated.'); // DEBUG LOG
      emit(AuthAuthenticated(currentUser));
    } else {
      print('### AuthBloc: Ningún usuario encontrado al inicializar. Emitiendo AuthUnauthenticated.'); // DEBUG LOG
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginWithGoogleRequested(
    AuthLoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('### AuthBloc: Recibido AuthLoginWithGoogleRequested. Emitiendo AuthLoading.'); // DEBUG LOG
    
    final result = await _loginWithGoogle();
    
    switch (result) {
      case AuthSuccess<User>():
        print('### AuthBloc: Login con Google exitoso. El usuario se emitirá automáticamente via AuthUserChanged.'); // DEBUG LOG
        // El usuario se emitirá automáticamente via AuthUserChanged
        break;
      case AuthFailure<User>():
        print('### AuthBloc: Fallo en Login con Google: ${result.exception.message}'); // DEBUG LOG
        emit(AuthError(result.exception.message));
        break;
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('### AuthBloc: Recibido AuthLogoutRequested. Emitiendo AuthLoading.'); // DEBUG LOG
    
    final result = await _logoutUser();
    
    switch (result) {
      case AuthSuccess():
        print('### AuthBloc: Logout exitoso. El estado se actualizará automáticamente via AuthUserChanged.'); // DEBUG LOG
        // El estado se actualizará automáticamente via AuthUserChanged
        break;
      case AuthFailure<User>():
        print('### AuthBloc: Fallo en Logout: ${result.exception.message}'); // DEBUG LOG
        emit(AuthError(result.exception.message));
        break;
    }
  }

  Future<void> _onGuestModeRequested(
    AuthGuestModeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    print('### AuthBloc: Recibido AuthGuestModeRequested. Emitiendo AuthLoading.'); // DEBUG LOG
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    final guestUser = _createGuestSession();
    print('### AuthBloc: Modo invitado activado. Emitiendo AuthAuthenticated (guest).'); // DEBUG LOG
    emit(AuthAuthenticated(guestUser));
  }

  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      print('### AuthBloc: AuthUserChanged: Usuario NO es null. Emitiendo AuthAuthenticated.'); // DEBUG LOG
      emit(AuthAuthenticated(event.user!));
    } else {
      print('### AuthBloc: AuthUserChanged: Usuario ES null. Emitiendo AuthUnauthenticated.'); // DEBUG LOG
      emit(AuthUnauthenticated());
    }
  }
}