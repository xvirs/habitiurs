import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../../../habits/presentation/bloc/habit_bloc.dart';
import '../../../habits/presentation/bloc/habit_event.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), elevation: 0),
      body: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsLoaded) {
            // Cuando cambia la configuración, reprogramar notificaciones
            // Usamos un try-catch por si el Bloc no está en el contexto (aunque debería)
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

                  // Sección de Información
                  const _SectionHeader(title: 'Información'),

                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Versión'),
                    subtitle: Text('1.0.0'),
                  ),

                  const Divider(),

                  // Resetear configuración
                  const _SectionHeader(title: 'Avanzado'),

                  ListTile(
                    leading: const Icon(Icons.restore, color: Colors.orange),
                    title: const Text('Restablecer configuración'),
                    subtitle: const Text('Volver a valores por defecto'),
                    onTap: () => _showResetDialog(context),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
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
