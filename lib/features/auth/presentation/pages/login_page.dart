// lib/features/auth/presentation/pages/login_page.dart - ACTUALIZADO
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Scrolleable para pantallas pequeñas / teclado, manteniendo
            // el layout expandido en pantallas normales.
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Spacer(),

                        // Logo y título
                        _buildHeader(context),

                        const Spacer(),

                        // Features highlights
                        _buildFeaturesList(context),

                        const SizedBox(height: 32),

                        // Login buttons
                        _buildAuthButtons(context),

                        const SizedBox(height: 16),

                        _buildTermsText(context),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.psychology,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Habitiurs',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Construye hábitos duraderos con IA',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    const features = [
      {
        'icon': Icons.psychology,
        'title': 'IA Personalizada',
        'description': 'Recomendaciones inteligentes basadas en tus patrones',
      },
      {
        'icon': Icons.analytics,
        'title': 'Estadísticas Avanzadas',
        'description': 'Analiza tu progreso con insights detallados',
      },
      {
        'icon': Icons.cloud_sync,
        'title': 'Sincronización',
        'description': 'Accede a tus datos desde cualquier dispositivo',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      feature['description'] as String,
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
      }).toList(),
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: isLoading ? null : () {
                  context.read<AuthBloc>().add(AuthLoginWithGoogleRequested());
                },
                icon: isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(isLoading ? 'Iniciando sesión...' : 'Continuar con Google'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: isLoading ? null : () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Modo sin cuenta'),
                      content: const Text(
                        'Tus hábitos se guardarán solo en este dispositivo. '
                        'No podrás sincronizarlos ni acceder desde otros dispositivos.\n\n'
                        'Si más adelante inicias sesión con Google, tus hábitos '
                        'se migrarán automáticamente a tu cuenta.\n\n'
                        '¿Deseas continuar?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            context
                                .read<AuthBloc>()
                                .add(AuthGuestSessionRequested());
                          },
                          child: const Text('Continuar'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Continuar sin cuenta'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermsText(BuildContext context) {
    return Text(
      'Al continuar, aceptas nuestros términos y condiciones',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
      ),
      textAlign: TextAlign.center,
    );
  }
}
