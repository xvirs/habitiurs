// lib/features/auth/presentation/bloc/auth_bloc.dart - NUEVO
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/core/auth/models/user_model.dart';
import '../../../../core/auth/services/auth_service.dart';
import '../../../../core/sync/services/sync_manager.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final SyncManager _syncManager;

  AuthBloc({
    required AuthService authService,
    required SyncManager syncManager,
  }) : _authService = authService,
       _syncManager = syncManager,
       super(AuthInitial()) {
    
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthSkipRequested>(_onAuthSkipRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      await Future.delayed(const Duration(milliseconds: 1000)); // Splash time
      
      final user = _authService.currentUser;
      if (user != null) {
        // Usuario logueado → iniciar sync automático
        _syncManager.resumeAutoSync();
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error verificando autenticación: $e'));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        // Login exitoso → sincronizar datos
        _syncManager.resumeAutoSync();
        await _syncManager.syncAll();
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error durante el login: $e'));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Pausar sync antes de logout
      _syncManager.pauseAutoSync();
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Error durante el logout: $e'));
    }
  }

  Future<void> _onAuthSkipRequested(
    AuthSkipRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      // Continuar sin cuenta → pausar sync
      _syncManager.pauseAutoSync();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Crear usuario temporal/guest
      final guestUser = _createGuestUser();
      emit(AuthAuthenticated(guestUser));
    } catch (e) {
      emit(AuthError('Error configurando modo offline: $e'));
    }
  }

  AppUser _createGuestUser() {
    return AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      email: 'guest@habitiurs.local',
      displayName: 'Usuario invitado',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isPremium: false,
      preferences: {'mode': 'guest'},
    );
  }
}