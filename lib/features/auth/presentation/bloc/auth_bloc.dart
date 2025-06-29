// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/core/auth/exceptions/auth_exceptions.dart';
import 'package:habitiurs/core/auth/models/auth_result.dart';
import 'package:habitiurs/core/auth/models/user.dart';
import 'package:habitiurs/core/di/injection_container.dart';
import 'package:habitiurs/features/auth/domain/usecases/check_auth_status.dart';
import 'package:habitiurs/features/auth/domain/usecases/create_guest_session.dart';
import 'package:habitiurs/features/auth/domain/usecases/login_with_google.dart';
import 'package:habitiurs/features/auth/domain/usecases/logout_user.dart';
// Importa los eventos de carga de datos de los otros Blocs
import '../../../habits/presentation/bloc/habit_event.dart';
import '../../../habits/presentation/bloc/habit_bloc.dart';
import '../../../statistics/presentation/bloc/statistics_event.dart';
import '../../../statistics/presentation/bloc/statistics_bloc.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_event.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithGoogle loginWithGoogle;
  final LogoutUser logoutUser;
  final CreateGuestSession createGuestSession;
  final CheckAuthStatus checkAuthStatus;

  final _initialSyncCompletedController = StreamController<void>.broadcast();

  AuthBloc({
    required this.loginWithGoogle,
    required this.logoutUser,
    required this.createGuestSession,
    required this.checkAuthStatus,
  }) : super(AuthInitial()) {
    on<AuthInitializationRequested>(_onAuthInitializationRequested);
    on<AuthLoginWithGoogleRequested>(_onAuthLoginWithGoogleRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthGuestSessionRequested>(_onAuthGuestSessionRequested);
  }

  Stream<void> get initialSyncCompletedStream =>
      _initialSyncCompletedController.stream;

  Future<void> _onAuthInitializationRequested(
    AuthInitializationRequested event,
    Emitter<AuthState> emit,
  ) async {
    print(
      '🔄 AuthBloc: AuthInitializationRequested - Verificando estado de autenticación inicial.',
    );
    emit(AuthLoading());
    await emit.forEach<User?>(
      checkAuthStatus.call(),
      onData: (user) {
        if (user != null) {
          print('✅ AuthBloc: Usuario autenticado: ${user.email}');
          // Dispara la carga inicial de datos para los otros Blocs
          _loadInitialAppData(); 
          if (!user.isGuest) {
            _startFullSync();
          }
          return AuthAuthenticated(user);
        } else {
          print(
            'ℹ️ AuthBloc: No hay usuario autenticado. Navegando a LoginPage.',
          );
          return AuthUnauthenticated();
        }
      },
      onError: (error, stackTrace) {
        print(
          '❌ AuthBloc: Error durante la inicialización de autenticación: $error',
        );
        return AuthError(
          'Error de autenticación inicial',
          technicalDetails: error.toString(),
        );
      },
    );
  }

  Future<void> _onAuthLoginWithGoogleRequested(
    AuthLoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    print(
      '🔄 AuthBloc: AuthLoginWithGoogleRequested - Iniciando login con Google.',
    );
    emit(AuthLoading());
    final result = await loginWithGoogle.call();
    if (result is AuthSuccess<User>) {
      print('✅ AuthBloc: Login con Google exitoso para: ${result.data.email}');
      _loadInitialAppData(); // Dispara la carga inicial de datos para los otros Blocs
      _startFullSync();
      emit(AuthAuthenticated(result.data));
    } else if (result is AuthFailure<User>) {
      print(
        '❌ AuthBloc: Fallo en el login con Google: ${result.exception.message}',
      );
      if (result.exception is LoginCancelledException) {
        print('ℹ️ AuthBloc: Login cancelado, volviendo a la página de login.');
        emit(AuthUnauthenticated());
      } else {
        emit(
          AuthError(
            result.exception.message,
            technicalDetails: result.exception.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔄 AuthBloc: AuthLogoutRequested - Iniciando cierre de sesión.');
    emit(AuthLoading());
    try {
      final result = await logoutUser.call();
      if (result is AuthSuccess<void>) {
        print('✅ AuthBloc: Cierre de sesión exitoso.');
        _stopFullSync();

        final databaseHelper = InjectionContainer().databaseHelper;
        await databaseHelper.clearAllData();
        print('✅ AuthBloc: Base de datos local borrada.');

        emit(AuthUnauthenticated());
        print('✅ AuthBloc: Emitido AuthUnauthenticated para ir a LoginPage.');
      } else if (result is AuthFailure<void>) {
        print(
          '❌ AuthBloc: Fallo en el cierre de sesión: ${result.exception.message}',
        );
        emit(
          AuthError(
            'Error al cerrar sesión',
            technicalDetails: result.exception.toString(),
          ),
        );
      }
    } catch (e, stackTrace) {
      print(
        '❌ AuthBloc: Excepción inesperada durante el cierre de sesión: $e\n$stackTrace',
      );
      emit(
        AuthError(
          'Error inesperado al cerrar sesión',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAuthGuestSessionRequested(
    AuthGuestSessionRequested event,
    Emitter<AuthState> emit,
  ) async {
    print(
      '🔄 AuthBloc: AuthGuestSessionRequested - Creando sesión de invitado.',
    );
    emit(AuthLoading());
    final guestUser = createGuestSession.call();
    _loadInitialAppData(); // Dispara la carga inicial de datos para los otros Blocs (solo datos locales)
    emit(AuthAuthenticated(guestUser));
    print('✅ AuthBloc: Sesión de invitado creada.');
  }

  // NUEVO MÉTODO: Para disparar la carga de datos inicial de los otros Blocs
  void _loadInitialAppData() {
    print('🔄 AuthBloc: Disparando eventos de carga inicial para HabitBloc, StatisticsBloc, AIAssistantBloc.');
    final container = InjectionContainer();
    container.habitBloc.add(LoadHabits());
    container.statisticsBloc.add(LoadStatistics());
    container.aiAssistantBloc.add(LoadAIAssistantData());
  }

  void _startFullSync() {
    final syncManager = InjectionContainer().syncManager;
    print(
      '🔄 AuthBloc: Iniciando sincronización completa a través de SyncManager.',
    );
    syncManager.resumeAutoSync();
    syncManager
        .syncAll()
        .then((success) {
          print(
            '✅ AuthBloc: Sincronización completa (inicio de sesión): $success',
          );
          _initialSyncCompletedController.add(null);
        })
        .catchError((e) {
          print('❌ AuthBloc: Error en sincronización inicial: $e');
        });
  }

  void _stopFullSync() {
    final syncManager = InjectionContainer().syncManager;
    print(
      '🔄 AuthBloc: Pausando sincronización automática a través de SyncManager.',
    );
    syncManager.pauseAutoSync();
  }

  @override
  Future<void> close() {
    print('🧹 AuthBloc: Cerrando y limpiando recursos.');
    //_initialSyncCompletedController.close();
    return super.close();
  }
}