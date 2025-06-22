// lib/features/app/presentation/pages/app_page.dart - PÁGINA PRINCIPAL
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/core/errors/app_error.dart';
import '../../../../core/bootstrap/app_state.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/pages/auth_wrapper.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/domain/usecases/login_with_google.dart';
import '../../../auth/domain/usecases/logout_user.dart';
import '../../../auth/domain/usecases/create_guest_session.dart';
import '../../../auth/domain/usecases/check_auth_status.dart';
import '../../../../core/auth/services/auth_service.dart';

class AppPage extends StatelessWidget {
  final AppState appState;
  
  const AppPage({
    Key? key,
    required this.appState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitiurs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    // Si hay error crítico, mostrar pantalla de error
    if (appState.hasError) {
      return ErrorScreen(
        error: appState.error!,
        onRetry: () {
          // TODO: Implementar retry mechanism
        },
        onOfflineMode: () {
          // TODO: Implementar modo offline
        },
      );
    }

    // Si inicialización fue exitosa, crear AuthBloc y mostrar app
    return _buildAuthenticatedApp();
  }

  Widget _buildAuthenticatedApp() {
    try {
      final authService = AuthService();
      
      return BlocProvider(
        create: (context) => AuthBloc(
          loginWithGoogle: LoginWithGoogle(authService),
          logoutUser: LogoutUser(authService),
          createGuestSession: CreateGuestSession(authService),
          checkAuthStatus: CheckAuthStatus(authService),
        )..add(AuthInitializationRequested()),
        child: const AuthWrapper(),
      );
    } catch (e) {
      return ErrorScreen(
        error: AppError(
          title: 'Error de autenticación',
          message: 'No se pudo inicializar el sistema de autenticación',
          technicalDetails: e.toString(),
          type: ErrorType.authentication,
        ),
      );
    }
  }
}
