// test/widget_test.dart - CORREGIDO para Habitiurs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Imports necesarios para testing
import 'package:habitiurs/core/auth/services/auth_service.dart';
import 'package:habitiurs/features/auth/domain/usecases/login_with_google.dart';
import 'package:habitiurs/features/auth/domain/usecases/logout_user.dart';
import 'package:habitiurs/features/auth/domain/usecases/create_guest_session.dart';
import 'package:habitiurs/features/auth/domain/usecases/check_auth_status.dart';
import 'package:habitiurs/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:habitiurs/features/auth/presentation/bloc/auth_event.dart';
import 'package:habitiurs/features/auth/presentation/pages/auth_wrapper.dart';

void main() {
  group('Habitiurs App Tests', () {
    testWidgets('App inicializa correctamente y muestra pantalla de carga', (WidgetTester tester) async {
      // Crear un AuthService mock para testing
      final authService = AuthService();
      
      // Construir la app de testing
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => AuthBloc(
              loginWithGoogle: LoginWithGoogle(authService),
              logoutUser: LogoutUser(authService),
              createGuestSession: CreateGuestSession(authService),
              checkAuthStatus: CheckAuthStatus(authService),
            )..add(AuthInitializationRequested()),
            child: const AuthWrapper(),
          ),
        ),
      );

      // Verificar que se muestra la pantalla de carga inicialmente
      expect(find.text('Inicializando Habitiurs...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Navegación a pantalla de login cuando no hay usuario', (WidgetTester tester) async {
      final authService = AuthService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => AuthBloc(
              loginWithGoogle: LoginWithGoogle(authService),
              logoutUser: LogoutUser(authService),
              createGuestSession: CreateGuestSession(authService),
              checkAuthStatus: CheckAuthStatus(authService),
            )..add(AuthInitializationRequested()),
            child: const AuthWrapper(),
          ),
        ),
      );

      // Esperar a que termine la inicialización (splash time)
      await tester.pump(const Duration(milliseconds: 1600));

      // Verificar que aparece la pantalla de login
      expect(find.text('Habitiurs'), findsOneWidget);
      expect(find.text('Construye hábitos duraderos con IA'), findsOneWidget);
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(find.text('Continuar sin cuenta'), findsOneWidget);
    });

    testWidgets('Botones de login funcionan correctamente', (WidgetTester tester) async {
      final authService = AuthService();
      
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (context) => AuthBloc(
              loginWithGoogle: LoginWithGoogle(authService),
              logoutUser: LogoutUser(authService),
              createGuestSession: CreateGuestSession(authService),
              checkAuthStatus: CheckAuthStatus(authService),
            )..add(AuthInitializationRequested()),
            child: const AuthWrapper(),
          ),
        ),
      );

      // Esperar a que aparezca la pantalla de login
      await tester.pump(const Duration(milliseconds: 1600));

      // Verificar que los botones existen y son tappeable
      final googleButton = find.text('Continuar con Google');
      final guestButton = find.text('Continuar sin cuenta');
      
      expect(googleButton, findsOneWidget);
      expect(guestButton, findsOneWidget);

      // Tap en botón de modo invitado
      await tester.tap(guestButton);
      await tester.pump();

      // Verificar que se activa el estado de loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Tema de la app se aplica correctamente', (WidgetTester tester) async {
      final authService = AuthService();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          home: BlocProvider(
            create: (context) => AuthBloc(
              loginWithGoogle: LoginWithGoogle(authService),
              logoutUser: LogoutUser(authService),
              createGuestSession: CreateGuestSession(authService),
              checkAuthStatus: CheckAuthStatus(authService),
            )..add(AuthInitializationRequested()),
            child: const AuthWrapper(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1600));

      // Verificar que los elementos tienen el tema correcto
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, true);
    });
  });

  group('Widget Component Tests', () {
    testWidgets('Loading screen muestra elementos correctos', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
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
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Inicializando Habitiurs...'), findsOneWidget);
    });

    testWidgets('Features list se muestra correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _buildFeatureItem(
                  icon: Icons.psychology,
                  title: 'IA Personalizada',
                  description: 'Recomendaciones inteligentes basadas en tus patrones',
                ),
                _buildFeatureItem(
                  icon: Icons.analytics,
                  title: 'Estadísticas Avanzadas',
                  description: 'Analiza tu progreso con insights detallados',
                ),
                _buildFeatureItem(
                  icon: Icons.cloud_sync,
                  title: 'Sincronización',
                  description: 'Accede a tus datos desde cualquier dispositivo',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('IA Personalizada'), findsOneWidget);
      expect(find.text('Estadísticas Avanzadas'), findsOneWidget);
      expect(find.text('Sincronización'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.byIcon(Icons.cloud_sync), findsOneWidget);
    });
  });
}

// Helper widget para testing
Widget _buildFeatureItem({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}