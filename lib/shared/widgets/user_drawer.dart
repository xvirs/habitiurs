// lib/shared/widgets/user_drawer.dart - VERSIÓN COMPLETA CON CALLBACK
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/auth/models/user.dart';
import '../../core/di/injection_container.dart';
import '../../core/sync/services/sync_manager.dart';
import '../../core/sync/models/sync_models.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class UserDrawer extends StatefulWidget {
  // ✅ NUEVO: Callback para notificar cambios a MainPage
  final VoidCallback? onDataSynced;
  
  const UserDrawer({
    Key? key,
    this.onDataSynced, // ← AGREGAR ESTE PARÁMETRO
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
                  _buildSyncSection(context), // ✅ ACTUALIZADO con sync real
                  const Divider(),
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

  // ✅ SECCIÓN DE SYNC COMPLETAMENTE ACTUALIZADA
  Widget _buildSyncSection(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isGuest = state is AuthAuthenticated ? state.user.isGuest : true;
        
        if (isGuest) {
          return ListTile(
            leading: Icon(
              Icons.cloud_off,
              color: Colors.grey[400],
            ),
            title: const Text('Sincronización no disponible'),
            subtitle: const Text('Inicia sesión para sincronizar'),
          );
        }

        // ✅ USUARIO AUTENTICADO: Mostrar estado de sync real
        return StreamBuilder<SyncStatus>(
          stream: _syncManager.syncStatus,
          builder: (context, statusSnapshot) {
            return StreamBuilder<bool>(
              stream: _syncManager.isSyncingStream,
              builder: (context, syncingSnapshot) {
                return StreamBuilder<DateTime?>(
                  stream: _syncManager.lastSyncTimeStream,
                  builder: (context, lastSyncSnapshot) {
                    final isSyncing = syncingSnapshot.data ?? false;
                    final lastSync = lastSyncSnapshot.data;
                    final status = statusSnapshot.data ?? SyncStatus.pending;
                    
                    return Column(
                      children: [
                        ListTile(
                          leading: _buildSyncIcon(status, isSyncing),
                          title: Text(_buildSyncTitle(status, isSyncing)),
                          subtitle: Text(_buildSyncSubtitle(lastSync, status)),
                          trailing: isSyncing 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: isSyncing ? null : () => _handleSyncTap(context),
                        ),
                        
                        // ✅ OPCIONES DE SYNC ESPECÍFICO (cuando no está syncing)
                        if (!isSyncing) 
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _handleSyncHabits(context),
                                    icon: const Icon(Icons.task_alt, size: 16),
                                    label: const Text('Hábitos'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () => _handleSyncEntries(context),
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    label: const Text('Entradas'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.green,
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  // ✅ HELPER METHODS PARA SYNC UI
  Widget _buildSyncIcon(SyncStatus status, bool isSyncing) {
    if (isSyncing) {
      return Icon(Icons.sync, color: Colors.blue[600]);
    }
    
    switch (status) {
      case SyncStatus.completed:
        return Icon(Icons.cloud_done, color: Colors.green[600]);
      case SyncStatus.failed:
        return Icon(Icons.cloud_off, color: Colors.red[600]);
      case SyncStatus.syncing:
        return Icon(Icons.sync, color: Colors.blue[600]);
      case SyncStatus.pending:
      case SyncStatus.conflict:
      default:
        return Icon(Icons.cloud_queue, color: Colors.orange[600]);
    }
  }

  String _buildSyncTitle(SyncStatus status, bool isSyncing) {
    if (isSyncing) return 'Sincronizando datos...';
    
    switch (status) {
      case SyncStatus.completed:
        return 'Datos sincronizados';
      case SyncStatus.failed:
        return 'Error de sincronización';
      case SyncStatus.conflict:
        return 'Conflicto detectado';
      case SyncStatus.pending:
      default:
        return 'Sincronizar datos';
    }
  }

  String _buildSyncSubtitle(DateTime? lastSync, SyncStatus status) {
    if (status == SyncStatus.failed) {
      return 'Toca para reintentar';
    }
    
    if (lastSync == null) {
      return 'Nunca sincronizado';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Última vez: hace un momento';
    } else if (difference.inHours < 1) {
      return 'Última vez: hace ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Última vez: hace ${difference.inHours} h';
    } else {
      return 'Última vez: hace ${difference.inDays} días';
    }
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

  // ✅ EVENT HANDLERS ACTUALIZADOS CON CALLBACK

  Future<void> _handleSyncTap(BuildContext context) async {
    Navigator.pop(context); // Cierra el Drawer
    
    try {
      print('🔄 [UI] Iniciando sincronización completa desde Drawer...');
      await _syncManager.syncAll();
      
      // ✅ NUEVO: Notificar a MainPage que actualice la UI
      widget.onDataSynced?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Sincronización completada'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [UI] Error en sincronización: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('❌ Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleSyncHabits(BuildContext context) async {
    try {
      print('🔄 [UI] Sincronizando solo hábitos...');
      final success = await _syncManager.syncHabitsOnly();
      
      // ✅ NUEVO: Notificar cambios si fue exitoso
      if (success) {
        widget.onDataSynced?.call();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.task_alt : Icons.error_outline, 
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(success 
                  ? '✅ Hábitos sincronizados' 
                  : '❌ Error sincronizando hábitos'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [UI] Error en sync de hábitos: $e');
    }
  }

  Future<void> _handleSyncEntries(BuildContext context) async {
    try {
      print('🔄 [UI] Sincronizando solo entradas...');
      final success = await _syncManager.syncEntriesOnly();
      
      // ✅ NUEVO: Notificar cambios si fue exitoso
      if (success) {
        widget.onDataSynced?.call();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.calendar_today : Icons.error_outline, 
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(success 
                  ? '✅ Entradas sincronizadas' 
                  : '❌ Error sincronizando entradas'),
              ],
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [UI] Error en sync de entradas: $e');
    }
  }

  void _handleSettingsTap(BuildContext context) {
    Navigator.pop(context); // Cierra el Drawer
    
    // TODO: Navegar a página de configuración
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración - Próximamente'),
        duration: Duration(seconds: 2),
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