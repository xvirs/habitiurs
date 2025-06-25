import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../habits/presentation/pages/main_page.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        print('### AuthWrapper Listener: Estado recibido: $state');
      },
      builder: (context, state) {
        print('### AuthWrapper Builder: Construyendo con estado: $state');
        if (state is AuthInitial || state is AuthLoading) {
          return const _LoadingPage();
        } else if (state is AuthAuthenticated) {
          return const MainPage();
        } else if (state is AuthUnauthenticated) {
          return const Text("LoginPagePlaceholder");
        } else if (state is AuthError) {
          return const Text("AuthErrorPagePlaceholder");
        }
        return const _LoadingPage();
      },
    );
  }
}

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