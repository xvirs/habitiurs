// lib/shared/widgets/user_drawer.dart
// 📱 User Drawer - REFACTORIZADO con AuthBloc

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/auth/services/auth_service.dart';
import '../../core/di/injection_container.dart';
import '../../core/sync/services/sync_manager.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class UserDrawer extends StatelessWidget {
  const UserDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = InjectionContainer().authService;
    final syncManager = InjectionContainer().syncManager;
    
    return BlocListener<AuthBloc, AuthState>(
      // ✅ Listener para mostrar mensajes automáticos
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
            _buildUserHeader(context, authService),
            
            // Opciones del drawer
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSyncSection(context, syncManager),
                  const Divider(),
                  _buildSettingsSection(context),
                  const Divider(),
                  _buildLogoutSection(context, authService),
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

  Widget _buildUserHeader(BuildContext context, AuthService authService) {
    final user = authService.currentUser;
    final isGuest = user?.preferences?['mode'] == 'guest';
    
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
  }

  Widget _buildSyncSection(BuildContext context, SyncManager syncManager) {
    return Column(
      children: [
        // Estado de sincronización
        StreamBuilder<bool>(
          stream: syncManager.isSyncingStream,
          builder: (context, snapshot) {
            final isSyncing = snapshot.data ?? false;
            
            return ListTile(
              leading: Icon(
                isSyncing ? Icons.sync : Icons.cloud_sync,
                color: isSyncing ? Colors.blue : Colors.grey[600],
              ),
              title: Text(
                isSyncing ? 'Sincronizando...' : 'Sincronizar datos',
              ),
              subtitle: StreamBuilder<DateTime?>(
                stream: syncManager.lastSyncTimeStream,
                builder: (context, snapshot) {
                  final lastSync = snapshot.data;
                  if (lastSync == null) {
                    return const Text('Nunca sincronizado');
                  }
                  
                  final now = DateTime.now();
                  final difference = now.difference(lastSync);
                  String timeAgo;
                  
                  if (difference.inMinutes < 1) {
                    timeAgo = 'Hace unos segundos';
                  } else if (difference.inHours < 1) {
                    timeAgo = 'Hace ${difference.inMinutes} min';
                  } else if (difference.inDays < 1) {
                    timeAgo = 'Hace ${difference.inHours} h';
                  } else {
                    timeAgo = 'Hace ${difference.inDays} días';
                  }
                  
                  return Text('Última vez: $timeAgo');
                },
              ),
              trailing: isSyncing 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: isSyncing ? null : () => _handleSyncTap(context, syncManager),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.settings_outlined,
        color: Colors.grey[600],
      ),
      title: const Text('Configuración'),
      subtitle: const Text('Preferencias y ajustes'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => _handleSettingsTap(context),
    );
  }

  Widget _buildLogoutSection(BuildContext context, AuthService authService) {
    final user = authService.currentUser;
    final isGuest = user?.preferences?['mode'] == 'guest';
    
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
      onTap: () => _handleAuthTap(context, authService, isGuest),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
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
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Habitiurs v1.0.0',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Simplicidad sobre complejidad',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ HANDLERS SIMPLIFICADOS - Usar AuthBloc
  void _handleSyncTap(BuildContext context, SyncManager syncManager) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Iniciando sincronización...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      await syncManager.requestSync();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronización completada ✓'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en sincronización: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleSettingsTap(BuildContext context) {
    Navigator.pop(context); // Cerrar drawer
    
    // TODO: Navegar a página de configuración
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración - Próximamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleAuthTap(BuildContext context, AuthService authService, bool isGuest) async {
    Navigator.pop(context); // Cerrar drawer
    
    if (isGuest) {
      // ✅ Usar AuthBloc para iniciar sesión
      context.read<AuthBloc>().add(AuthLoginRequested());
    } else {
      // Mostrar diálogo de confirmación para cerrar sesión
      final shouldLogout = await showDialog<bool>(
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
      
      if (shouldLogout == true) {
        // ✅ Usar AuthBloc para cerrar sesión
        // La navegación será automática cuando cambie el estado
        context.read<AuthBloc>().add(AuthLogoutRequested());
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cerrando sesión...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }
}