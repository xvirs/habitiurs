import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';
import '../../../habits/presentation/pages/main_page.dart';

/// Widget que maneja la navegación entre auth y app principal
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        print('### AuthWrapper Listener: Estado recibido: $state'); // DEBUG LOG
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        print('### AuthWrapper Builder: Construyendo con estado: $state'); // DEBUG LOG
        switch (state) {
          case AuthInitial():
          case AuthLoading():
            return const _LoadingPage();
            
          case AuthAuthenticated():
            return const MainPage();
            
          case AuthUnauthenticated():
            print('### AuthWrapper Builder: Retornando LoginPage.'); // DEBUG LOG
            return const LoginPage();
            
          case AuthError():
            return const _ErrorPage();
        }
        // Fallback in case none of the cases match
        print('### AuthWrapper Builder: Estado desconocido. Retornando Scaffold genérico.'); // DEBUG LOG
        return const Scaffold(
          body: Center(child: Text('Estado desconocido')),
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    print('### _LoadingPage creado/reconstruido'); // DEBUG LOG
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Inicializando Habitiurs...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage();

  @override
  Widget build(BuildContext context) {
    print('### _ErrorPage creado/reconstruido'); // DEBUG LOG
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Error de inicialización',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(AuthInitializationRequested());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}