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
import 'package:habitiurs/features/auth/domain/usecases/login_with_apple.dart';
import 'package:habitiurs/features/auth/domain/usecases/logout_user.dart';
// Importa los eventos de carga de datos de los otros Blocs
import '../../../habits/presentation/bloc/habit_event.dart';
import '../../../statistics/presentation/bloc/statistics_event.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_event.dart';

import 'auth_event.dart';
import 'auth_state.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithGoogle loginWithGoogle;
  final LoginWithApple loginWithApple;
  final LogoutUser logoutUser;
  final CreateGuestSession createGuestSession;
  final CheckAuthStatus checkAuthStatus;

  final _initialSyncCompletedController = StreamController<void>.broadcast();
  bool _initialDataLoaded = false;
  bool _syncCompleted = false;
  bool _syncStarted = false;
  bool get isSyncCompleted => _syncCompleted;

  AuthBloc({
    required this.loginWithGoogle,
    required this.loginWithApple,
    required this.logoutUser,
    required this.createGuestSession,
    required this.checkAuthStatus,
  }) : super(AuthInitial()) {
    on<AuthInitializationRequested>(_onAuthInitializationRequested);
    on<AuthLoginWithGoogleRequested>(_onAuthLoginWithGoogleRequested);
    on<AuthLoginWithAppleRequested>(_onAuthLoginWithAppleRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthGuestSessionRequested>(_onAuthGuestSessionRequested);
  }

  Stream<void> get initialSyncCompletedStream =>
      _initialSyncCompletedController.stream;

  Future<void> _onAuthInitializationRequested(
    AuthInitializationRequested event,
    Emitter<AuthState> emit,
  ) async {
    appLog(
      '🔄 AuthBloc: AuthInitializationRequested - Verificando estado de autenticación inicial.',
    );
    emit(AuthLoading());
    await emit.forEach<User?>(
      checkAuthStatus.call(),
      onData: (user) {
        if (user != null) {
          appLog('✅ AuthBloc: Usuario autenticado: ${user.email}');
          // Dispara la carga inicial de datos para los otros Blocs
          _loadInitialAppData(); 
          if (!user.isGuest) {
            _startFullSync();
          }
          return AuthAuthenticated(user);
        } else {
          appLog(
            'ℹ️ AuthBloc: No hay usuario autenticado. Navegando a LoginPage.',
          );
          return AuthUnauthenticated();
        }
      },
      onError: (error, stackTrace) {
        appLog(
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
    appLog(
      '🔄 AuthBloc: AuthLoginWithGoogleRequested - Iniciando login con Google.',
    );
    emit(AuthLoading(message: 'Iniciando sesión...'));
    final result = await loginWithGoogle.call();
    if (result is AuthSuccess<User>) {
      appLog('✅ AuthBloc: Login con Google exitoso para: ${result.data.email}');
      _loadInitialAppData(); // Dispara la carga inicial de datos para los otros Blocs
      _startFullSync();
      emit(AuthAuthenticated(result.data));
    } else if (result is AuthFailure<User>) {
      appLog(
        '❌ AuthBloc: Fallo en el login con Google: ${result.exception.message}',
      );
      if (result.exception is LoginCancelledException) {
        appLog('ℹ️ AuthBloc: Login cancelado, volviendo a la página de login.');
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

  Future<void> _onAuthLoginWithAppleRequested(
    AuthLoginWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    appLog('🔄 AuthBloc: AuthLoginWithAppleRequested - Iniciando login con Apple.');
    emit(AuthLoading(message: 'Iniciando sesión...'));
    final result = await loginWithApple.call();
    if (result is AuthSuccess<User>) {
      appLog('✅ AuthBloc: Login con Apple exitoso para: ${result.data.email}');
      _loadInitialAppData();
      _startFullSync();
      emit(AuthAuthenticated(result.data));
    } else if (result is AuthFailure<User>) {
      appLog('❌ AuthBloc: Fallo en el login con Apple: ${result.exception.message}');
      if (result.exception is LoginCancelledException) {
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
    appLog('🔄 AuthBloc: AuthLogoutRequested - Iniciando cierre de sesión.');
    emit(AuthLoading(message: 'Cerrando sesión...'));
    try {
      // Sincronizar datos a Firebase ANTES de cerrar sesión y borrar la BD local.
      // Garantiza que las entradas marcadas (completed/skipped) no se pierdan
      // si el fire-and-forget sync posterior a cada acción no había terminado.
      final syncManager = InjectionContainer().syncManager;
      appLog('🔄 AuthBloc: Sincronizando datos antes de cerrar sesión...');
      await syncManager.syncAll().catchError((e) {
        appLog('⚠️ AuthBloc: Sync previo al logout no completado (sin internet o error): $e');
        return false;
      });

      final result = await logoutUser.call();
      if (result is AuthSuccess<void>) {
        appLog('✅ AuthBloc: Cierre de sesión exitoso.');
        _initialDataLoaded = false;
        _syncCompleted = false;
        _syncStarted = false;
        _stopFullSync();

        final databaseHelper = InjectionContainer().databaseHelper;
        await databaseHelper.clearAllData();
        appLog('✅ AuthBloc: Base de datos local borrada.');

        emit(AuthUnauthenticated());
        appLog('✅ AuthBloc: Emitido AuthUnauthenticated para ir a LoginPage.');
      } else if (result is AuthFailure<void>) {
        appLog(
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
      appLog(
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
    appLog(
      '🔄 AuthBloc: AuthGuestSessionRequested - Creando sesión de invitado.',
    );
    emit(AuthLoading());
    final guestUser = createGuestSession.call();
    _loadInitialAppData(); // Dispara la carga inicial de datos para los otros Blocs (solo datos locales)
    emit(AuthAuthenticated(guestUser));
    appLog('✅ AuthBloc: Sesión de invitado creada.');
  }

  // Dispara la carga inicial de datos una sola vez por sesión
  void _loadInitialAppData() {
    if (_initialDataLoaded) return;
    _initialDataLoaded = true;
    appLog('🔄 AuthBloc: Disparando eventos de carga inicial para HabitBloc, StatisticsBloc, AIAssistantBloc.');
    final container = InjectionContainer();
    container.habitBloc.add(LoadHabits());
    container.statisticsBloc.add(LoadStatistics());
    container.aiAssistantBloc.add(LoadAIAssistantData());
  }

  void _startFullSync() {
    // Guard: evita doble sync cuando authStateChanges y loginWithGoogle completan casi al mismo tiempo
    if (_syncStarted) {
      appLog('⚠️ AuthBloc: _startFullSync() ignorado (sync ya iniciado).');
      return;
    }
    _syncStarted = true;

    final syncManager = InjectionContainer().syncManager;
    appLog(
      '🔄 AuthBloc: Iniciando sincronización completa a través de SyncManager.',
    );
    syncManager.resumeAutoSync();
    syncManager
        .syncAll()
        .then((success) {
          appLog(
            '✅ AuthBloc: Sincronización completa (inicio de sesión): $success',
          );
          _syncCompleted = true;
          _initialSyncCompletedController.add(null);
          if (success) {
            appLog('🔄 AuthBloc: Recargando datos de UI tras sync inicial...');
            final container = InjectionContainer();
            container.habitBloc.add(RefreshData());
            container.statisticsBloc.add(LoadStatistics());
          }
        })
        .catchError((e) {
          appLog('❌ AuthBloc: Error en sincronización inicial: $e');
          _syncCompleted = true;
          _initialSyncCompletedController.add(null);
        });
  }

  void _stopFullSync() {
    final syncManager = InjectionContainer().syncManager;
    appLog(
      '🔄 AuthBloc: Pausando sincronización automática a través de SyncManager.',
    );
    syncManager.pauseAutoSync();
  }

  @override
  Future<void> close() {
    appLog('🧹 AuthBloc: Cerrando y limpiando recursos.');
    _initialSyncCompletedController.close();
    return super.close();
  }
}