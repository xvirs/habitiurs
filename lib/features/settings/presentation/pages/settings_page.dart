import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/auth/models/auth_result.dart';
import '../../../../core/auth/services/account_deletion_service.dart';
import '../../../../core/constants/legal_constants.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../habits/presentation/bloc/habit_bloc.dart';
import '../../../habits/presentation/bloc/habit_event.dart';
import '../../../habits/presentation/pages/archived_habits_page.dart';
import '../../../../shared/utils/responsive.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), elevation: 0),
      body: CenteredContent(
        child: BlocListener<SettingsBloc, SettingsState>(
          listenWhen: (previous, current) {
            // Solo reprogramar cuando la configuración realmente cambia,
            // no en la carga inicial de la página.
            if (current is! SettingsLoaded) return false;
            if (previous is! SettingsLoaded) return false;
            return previous.settings != current.settings;
          },
          listener: (context, state) {
            if (state is SettingsLoaded) {
              try {
                context.read<HabitBloc>().add(RescheduleNotifications());
              } catch (_) {}
            }
          },
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is SettingsError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (state is SettingsLoaded) {
                final settings = state.settings;

                return ListView(
                  children: [
                    // Sección de Notificaciones
                    const _SectionHeader(title: 'Notificaciones'),

                    SwitchListTile(
                      title: const Text('Recordatorio diario'),
                      subtitle: const Text(
                        'Recibir notificación con hábitos pendientes',
                      ),
                      value: settings.notificationsEnabled,
                      onChanged: (value) {
                        context.read<SettingsBloc>().add(
                          ToggleNotifications(value),
                        );
                      },
                    ),

                    if (settings.notificationsEnabled)
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Hora de recordatorio'),
                        subtitle: Text(settings.formattedNotificationTime),
                        trailing: const Icon(Icons.chevron_right),
                        onTap:
                            () => _showTimePicker(
                              context,
                              settings.notificationHour,
                              settings.notificationMinute,
                            ),
                      ),

                    const Divider(),

                    // Sección de Hábitos
                    const _SectionHeader(title: 'Hábitos'),

                    ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: const Text('Hábitos archivados'),
                      subtitle: const Text('Restaurar o eliminar hábitos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ArchivedHabitsPage(),
                          ),
                        );
                      },
                    ),

                    const Divider(),

                    // Sección Legal
                    const _SectionHeader(title: 'Legal'),

                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Política de privacidad'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap:
                          () => _openUrl(
                            context,
                            LegalConstants.privacyPolicyUrl,
                          ),
                    ),

                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Términos y condiciones'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap:
                          () => _openUrl(
                            context,
                            LegalConstants.termsOfServiceUrl,
                          ),
                    ),

                    const Divider(),

                    // Sección de Información
                    const _SectionHeader(title: 'Información'),

                    const _VersionTile(),

                    const Divider(),

                    // Avanzado
                    const _SectionHeader(title: 'Avanzado'),

                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.orange),
                      title: const Text('Restablecer configuración'),
                      subtitle: const Text('Volver a valores por defecto'),
                      onTap: () => _showResetDialog(context),
                    ),

                    ListTile(
                      leading: Icon(
                        Icons.delete_forever_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Eliminar cuenta',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      subtitle: const Text(
                        'Borra tu cuenta y todos tus datos de forma permanente',
                      ),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),

                    const SizedBox(height: 24),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<void> _showTimePicker(
    BuildContext context,
    int currentHour,
    int currentMinute,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      context.read<SettingsBloc>().add(
        UpdateNotificationTime(picked.hour, picked.minute),
      );
    }
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('¿Restablecer configuración?'),
            content: const Text(
              'Se restaurarán todos los ajustes a sus valores por defecto.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Restablecer'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SettingsBloc>().add(const ResetSettings());
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('¿Eliminar cuenta?'),
            content: const Text(
              'Esta acción es permanente y no se puede deshacer.\n\n'
              'Se eliminarán tu cuenta, todos tus hábitos, tu historial '
              'y tus datos sincronizados en la nube.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Eliminar para siempre'),
              ),
            ],
          ),
    );

    if (confirmed != true || !context.mounted) return;

    final authBloc = context.read<AuthBloc>();

    // Mostrar progreso mientras se borra
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await AccountDeletionService().deleteAccount();

    if (!context.mounted) return;
    Navigator.of(context).pop(); // Cerrar el indicador de progreso

    if (result is AuthSuccess) {
      // Volver a la raíz; el AuthBloc lleva a la pantalla de login
      Navigator.of(context).popUntil((route) => route.isFirst);
      authBloc.add(AuthLogoutRequested());
    } else if (result is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la cuenta: ${result.exception.message}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Versión'),
          subtitle: Text(
            info == null ? '…' : '${info.version} (${info.buildNumber})',
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
