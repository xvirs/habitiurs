// lib/shared/widgets/user_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/auth/models/user.dart';
import '../../core/di/injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/bloc/settings_event.dart';
import '../../features/settings/presentation/bloc/settings_state.dart';
import '../../features/habits/presentation/bloc/habit_bloc.dart';
import '../../features/habits/presentation/bloc/habit_event.dart';
import '../../features/habits/presentation/pages/archived_habits_page.dart';
import '../../features/ai_assistant/presentation/bloc/ai_assistant_event.dart';
import '../../features/ai_assistant/presentation/bloc/ai_assistant_state.dart';
import '../../features/ai_assistant/presentation/pages/ai_assistant_page.dart';

/// Drawer como "centro de control": accesos rápidos y los ajustes más
/// recurrentes (Misiones, recordatorio diario) sin entrar a Configuración.
class UserDrawer extends StatefulWidget {
  final VoidCallback? onDataSynced;

  const UserDrawer({Key? key, this.onDataSynced}) : super(key: key);
  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  @override
  void initState() {
    super.initState();
    // Asegura que los toggles tengan datos aunque el arranque no los cargara.
    final settingsBloc = InjectionContainer().settingsBloc;
    if (settingsBloc.state is! SettingsLoaded) {
      settingsBloc.add(const LoadSettings());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Drawer(
        child: Column(
          children: [
            _buildUserHeader(context),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final settings =
                          state is SettingsLoaded ? state.settings : null;
                      final missionsEnabled = settings?.missionsEnabled ?? true;
                      final notificationsEnabled =
                          settings?.notificationsEnabled ?? true;

                      return Column(
                        children: [
                          _sectionLabel(context, 'Accesos'),
                          // El Asistente IA vive acá cuando Misiones ocupa su
                          // lugar en la barra inferior.
                          if (missionsEnabled)
                            ListTile(
                              leading: const Icon(Icons.psychology_outlined),
                              title: const Text('Asistente IA'),
                              trailing: const Icon(
                                Icons.chevron_right,
                                size: 20,
                              ),
                              onTap: () => _openAIAssistant(context),
                            ),
                          ListTile(
                            leading: const Icon(Icons.archive_outlined),
                            title: const Text('Hábitos archivados'),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => _openArchivedHabits(context),
                          ),

                          const Divider(height: 8),
                          _sectionLabel(context, 'Ajustes rápidos'),

                          SwitchListTile(
                            secondary: const Icon(Icons.flag_outlined),
                            title: const Text('Misiones'),
                            subtitle: const Text('Tareas de una sola vez'),
                            value: missionsEnabled,
                            onChanged:
                                settings == null
                                    ? null
                                    : (v) => context.read<SettingsBloc>().add(
                                      ToggleMissions(v),
                                    ),
                          ),
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications_outlined),
                            title: const Text('Recordatorio diario'),
                            subtitle: const Text('Aviso de hábitos pendientes'),
                            value: notificationsEnabled,
                            onChanged:
                                settings == null
                                    ? null
                                    : (v) => _toggleNotifications(context, v),
                          ),
                          if (notificationsEnabled && settings != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.access_time,
                                  size: 20,
                                ),
                                title: const Text('Hora'),
                                trailing: Text(
                                  settings.formattedNotificationTime,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                onTap:
                                    () => _pickReminderTime(
                                      context,
                                      settings.notificationHour,
                                      settings.notificationMinute,
                                    ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const Divider(),
                  _buildSettingsSection(context),
                  _buildLogoutSection(context),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        User? user;
        if (state is AuthAuthenticated) {
          user = state.user;
        }
        final isGuest = user?.isGuest ?? true;

        return Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 35, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage:
                    user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    user?.photoURL == null
                        ? Icon(
                          isGuest ? Icons.person_outline : Icons.person,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user?.displayName ?? 'Usuario invitado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'guest@habitiurs.local',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isGuest ? Colors.orange[300] : Colors.green[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGuest ? 'Invitado' : 'Conectado',
                        style: TextStyle(
                          color:
                              isGuest ? Colors.orange[800] : Colors.green[800],
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.settings_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: const Text('Configuración'),
      subtitle: const Text('Legal, versión y cuenta'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _handleSettingsTap(context),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }
        final isGuest = state.user.isGuest;
        return ListTile(
          leading: Icon(
            isGuest ? Icons.login : Icons.logout,
            color: isGuest ? Colors.green[600] : Colors.red[600],
          ),
          title: Text(isGuest ? 'Iniciar sesión' : 'Cerrar sesión'),
          subtitle: Text(
            isGuest
                ? 'Conecta tu cuenta de Google'
                : 'Salir de tu cuenta actual',
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _handleAuthTap(context, isGuest),
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.apps,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Habitiurs v1.0.0',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Simplicidad sobre complejidad',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Acciones ──────────────────────────────────────────────────────────

  void _toggleNotifications(BuildContext context, bool enabled) {
    context.read<SettingsBloc>().add(ToggleNotifications(enabled));
    // Reprograma/cancela el recordatorio diario según el nuevo valor.
    try {
      context.read<HabitBloc>().add(RescheduleNotifications());
    } catch (_) {}
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    int hour,
    int minute,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (picked != null && context.mounted) {
      context.read<SettingsBloc>().add(
        UpdateNotificationTime(picked.hour, picked.minute),
      );
      try {
        context.read<HabitBloc>().add(RescheduleNotifications());
      } catch (_) {}
    }
  }

  void _openAIAssistant(BuildContext context) {
    Navigator.pop(context);
    final aiBloc = InjectionContainer().aiAssistantBloc;
    if (aiBloc.state is AIAssistantInitial) {
      aiBloc.add(LoadAIAssistantData());
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: aiBloc,
              child: Scaffold(
                appBar: AppBar(title: const Text('Asistente IA')),
                body: const AIAssistantPage(),
              ),
            ),
      ),
    );
  }

  void _openArchivedHabits(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => BlocProvider.value(
              value: InjectionContainer().habitBloc,
              child: const ArchivedHabitsPage(),
            ),
      ),
    );
  }

  void _handleSettingsTap(BuildContext context) {
    Navigator.pop(context);
    final settingsBloc = InjectionContainer().settingsBloc;
    settingsBloc.add(const LoadSettings());
    final authBloc = BlocProvider.of<AuthBloc>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: settingsBloc),
                BlocProvider.value(value: authBloc),
                BlocProvider.value(value: InjectionContainer().habitBloc),
              ],
              child: const SettingsPage(),
            ),
      ),
    );
  }

  void _handleAuthTap(BuildContext context, bool isGuest) async {
    Navigator.pop(context);
    final authBloc = BlocProvider.of<AuthBloc>(context, listen: false);
    if (isGuest) {
      authBloc.add(AuthLoginWithGoogleRequested());
    } else {
      final shouldLogout = await _showLogoutConfirmation(context);
      if (shouldLogout == true) {
        authBloc.add(AuthLogoutRequested());
      }
    }
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text(
              '¿Estás seguro de que quieres cerrar sesión? '
              'Tus datos se mantendrán sincronizados en la nube.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );
  }
}
