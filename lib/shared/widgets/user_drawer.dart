// lib/shared/widgets/user_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/auth/models/user.dart';
import '../../core/di/injection_container.dart';
import '../../core/sync/services/sync_manager.dart';
import '../../core/sync/models/sync_models.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/settings/presentation/bloc/settings_event.dart';

class UserDrawer extends StatefulWidget {
  final VoidCallback? onDataSynced;
  
  const UserDrawer({
    Key? key,
    this.onDataSynced,
  }) : super(key: key);
  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  late final SyncManager _syncManager;
  @override
  void initState() {
    super.initState();
    _syncManager = InjectionContainer().syncManager;
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
            // Header con información del usuario
            _buildUserHeader(context),
            // Opciones del drawer
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // MODIFIED: Remove sync section. Sync is now handled by pull-to-refresh and auto-sync.
                  // _buildSyncSection(context),
                  // const Divider(),
                  _buildSettingsSection(context),
                  const Divider(),
                  _buildLogoutSection(context),
                ],
              ),
            ),
            // Footer con versión de la app
            _buildFooter(context),
          ],
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
              // Avatar del usuario
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage: user?.photoURL != null 
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL == null
                    ? Icon(
                        isGuest ? Icons.person_outline : Icons.person,
                        size: 22,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Nombre del usuario
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
                    // Email del usuario
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
                    
                    // Badge de cuenta
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGuest ? Colors.orange[300] : Colors.green[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGuest ? 'Invitado' : 'Conectado',
                        style: TextStyle(
                          color: isGuest ? Colors.orange[800] : Colors.green[800],
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
      subtitle: const Text('Preferencias y ajustes'),
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
          title: Text(
            isGuest ? 'Iniciar sesión' : 'Cerrar sesión',
          ),
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
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
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

  // MODIFIED: Simplified event handlers since explicit sync buttons are removed

  void _handleSettingsTap(BuildContext context) {
    Navigator.pop(context);

    // Obtener el SettingsBloc del contenedor de inyección de dependencias
    final settingsBloc = InjectionContainer().settingsBloc;

    // Cargar configuración y navegar
    settingsBloc.add(const LoadSettings());

    // La ruta pierde los providers del árbol principal: pasar los blocs
    // necesarios explícitamente (AuthBloc para borrado de cuenta,
    // HabitBloc para reprogramar notificaciones y archivados).
    final authBloc = BlocProvider.of<AuthBloc>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
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
      builder: (context) => AlertDialog(
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