import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/auth/presentation/pages/login_page.dart';
import '../../../habits/presentation/pages/main_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocConsumer observa los cambios de estado y reconstruye la UI.
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        print('### AuthWrapper Listener: Estado recibido: $state');
        // No se realiza ninguna navegación explícita (Navigator.push, etc.) aquí.
        // La navegación se gestiona implícitamente por el 'builder'
        // al cambiar el widget raíz que se muestra en respuesta al estado.
        // Esto previene el error "Provider not found" al evitar que el listener
        // intente manipular el navegador mientras el builder podría estar re-evaluando
        // su contexto.
        // La responsabilidad de limpiar la pila de navegación (si se desea)
        // recae en la forma en que se maneja la navegación *después* de un login exitoso
        // (usando pushReplacement desde LoginPage) o al iniciar la app.
      },
      builder: (context, state) {
        print('### AuthWrapper Builder: Construyendo con estado: $state');
        // Muestra un indicador de carga mientras el estado inicial se determina
        if (state is AuthInitial || state is AuthLoading) {
          return const _LoadingPage();
        } 
        // Si el usuario está autenticado, muestra la página principal de la aplicación.
        // Esto incluye tanto usuarios logueados con Google como usuarios invitados.
        else if (state is AuthAuthenticated) {
          return const MainPage();
        } 
        // Si el usuario no está autenticado (incluyendo después de cerrar sesión
        // o al iniciar la app sin una sesión previa), se muestra la LoginPage.
        // El AuthBloc ahora emitirá AuthUnauthenticated directamente cuando no haya sesión.
        else if (state is AuthUnauthenticated) {
          return const LoginPage();
        } 
        // En caso de un estado de error inesperado o no manejado,
        // puedes mostrar un mensaje de error o una pantalla de error dedicada.
        else if (state is AuthError) {
          // Considera usar una pantalla de ErrorScreen más robusta aquí si es necesario
          return Text(
            "AuthError: ${state.message}",
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          );
        }
        // Fallback: Si ningún estado coincide, se muestra una página de carga por defecto.
        // Esto rara vez debería ocurrir si todos los estados están cubiertos.
        return const _LoadingPage();
      },
    );
  }
}

/// Widget simple para mostrar un indicador de carga.
class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    print('### _LoadingPage creado/reconstruido');
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
