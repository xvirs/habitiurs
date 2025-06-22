// lib/shared/widgets/sync_debug_widget.dart - WIDGET PARA DEBUGGING
import 'package:flutter/material.dart';
import '../../core/di/injection_container.dart';
import '../../core/sync/models/sync_models.dart';

class SyncDebugWidget extends StatefulWidget {
  const SyncDebugWidget({Key? key}) : super(key: key);

  @override
  State<SyncDebugWidget> createState() => _SyncDebugWidgetState();
}

class _SyncDebugWidgetState extends State<SyncDebugWidget> {
  final _syncRepo = InjectionContainer().syncRepository;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔧 Debug de Sincronización',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Estado de sync
            StreamBuilder<SyncStatus>(
              stream: _syncRepo.syncStatus,
              builder: (context, snapshot) {
                final status = snapshot.data ?? SyncStatus.pending;
                return Row(
                  children: [
                    const Text('Estado: '),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Indicador de sincronización
            StreamBuilder<bool>(
              stream: _syncRepo.isSyncing,
              builder: (context, snapshot) {
                final isSyncing = snapshot.data ?? false;
                return Row(
                  children: [
                    const Text('Sincronizando: '),
                    Icon(
                      isSyncing ? Icons.sync : Icons.sync_disabled,
                      color: isSyncing ? Colors.blue : Colors.grey,
                    ),
                    Text(isSyncing ? ' SÍ' : ' NO'),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Última sincronización
            StreamBuilder<DateTime?>(
              stream: _syncRepo.lastSyncTime,
              builder: (context, snapshot) {
                final lastSync = snapshot.data;
                return Row(
                  children: [
                    const Text('Último sync: '),
                    Text(
                      lastSync != null 
                        ? '${lastSync.day}/${lastSync.month} ${lastSync.hour}:${lastSync.minute.toString().padLeft(2, '0')}'
                        : 'Nunca',
                      style: TextStyle(
                        color: lastSync != null ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botones de acción
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _syncRepo.syncAll(),
                  icon: const Icon(Icons.sync, size: 16),
                  label: const Text('Sync Todo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () => _syncRepo.syncHabitsOnly(),
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('Solo Hábitos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                ElevatedButton.icon(
                  onPressed: () => _syncRepo.syncEntriesOnly(),
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('Solo Entradas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Botones de control
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _syncRepo.pauseAutoSync(),
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('Pausar Auto-sync'),
                ),
                
                TextButton.icon(
                  onPressed: () => _syncRepo.resumeAutoSync(),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Reanudar'),
                ),
              ],
            ),
            
            // Información adicional
            FutureBuilder<bool>(
              future: _syncRepo.hasInternetConnection(),
              builder: (context, snapshot) {
                final hasConnection = snapshot.data ?? false;
                return Row(
                  children: [
                    Icon(
                      hasConnection ? Icons.wifi : Icons.wifi_off,
                      color: hasConnection ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasConnection ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: hasConnection ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.conflict:
        return Colors.orange;
    }
  }
  
  String _getStatusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return 'Pendiente';
      case SyncStatus.syncing:
        return 'Sincronizando';
      case SyncStatus.completed:
        return 'Completado';
      case SyncStatus.failed:
        return 'Error';
      case SyncStatus.conflict:
        return 'Conflicto';
    }
  }
}