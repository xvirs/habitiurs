// lib/core/sync/services/sync_manager.dart - CORREGIDO PARA MULTI-DISPOSITIVO
import 'dart:async';
import '../services/firebase_service.dart';
import '../../auth/interfaces/i_auth_service.dart';
import '../../auth/models/user.dart';
import '../models/sync_models.dart';

// Imports para acceso a datasources
import '../../../features/habits/data/datasources/habit_local_datasource.dart';
import '../../../features/statistics/data/datasources/statistics_local_datasource.dart';
import '../../../features/habits/data/models/habit_model.dart';
import '../../../features/habits/data/models/habit_entry_model.dart';
import '../../../shared/enums/habit_status.dart';

class SyncManager {
  final FirebaseService _firebaseService;
  final IAuthService _authService;
  final HabitLocalDataSource _habitDataSource;
  final StatisticsLocalDatasource _statisticsDataSource;
  
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Stream controllers para estado de sync
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  final _lastSyncController = StreamController<DateTime?>.broadcast();
  final _isSyncingController = StreamController<bool>.broadcast();

  SyncManager({
    required FirebaseService firebaseService,
    required IAuthService authService,
    required HabitLocalDataSource habitDataSource,
    required StatisticsLocalDatasource statisticsDataSource,
  }) : _firebaseService = firebaseService,
       _authService = authService,
       _habitDataSource = habitDataSource,
       _statisticsDataSource = statisticsDataSource {
    _initializeAutoSync();
  }

  // Streams públicos
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  Stream<DateTime?> get lastSyncTime => _lastSyncController.stream;
  Stream<bool> get isSyncingStream => _isSyncingController.stream;
  Stream<DateTime?> get lastSyncTimeStream => _lastSyncController.stream;
  
  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSyncTime;

  void _initializeAutoSync() {
    // Auto-sync cada 30 minutos si hay usuario logueado
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      final user = _authService.currentUser;
      if (user != null && !user.isGuest && !_isSyncing) {
        syncAll();
      }
    });
  }

  /// Sincronización completa manual
  Future<bool> syncAll() async {
    final user = _authService.currentUser;
    if (user == null) {
      print('⚠️ [Sync] No hay usuario logueado');
      return false;
    }

    if (user.isGuest) {
      print('⚠️ [Sync] Usuario invitado - sync no disponible');
      return false;
    }

    if (_isSyncing) {
      print('⚠️ [Sync] Ya hay sincronización en progreso');
      return false;
    }

    try {
      _setIsSyncing(true);
      _syncStatusController.add(SyncStatus.syncing);
      
      print('🔄 [Sync] Iniciando sincronización completa para usuario: ${user.email}');

      // 1. Verificar conectividad
      final hasConnection = await _firebaseService.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('Sin conexión a internet');
      }

      // 2. Sincronizar usuario
      await _syncUser(user);

      // 3. ✅ CORREGIDO: Sincronizar hábitos con merge bidireccional completo
      await _syncHabitsWithBidirectionalMerge(user.id);

      // 4. ✅ CORREGIDO: Sincronizar entradas con merge bidireccional completo
      await _syncHabitEntriesWithBidirectionalMerge(user.id);

      _setLastSyncTime(DateTime.now());
      _syncStatusController.add(SyncStatus.completed);

      print('✅ [Sync] Sincronización completada exitosamente');
      return true;

    } catch (e) {
      print('❌ [Sync] Error: $e');
      _syncStatusController.add(SyncStatus.failed);
      rethrow;
    } finally {
      _setIsSyncing(false);
    }
  }

  Future<void> _syncUser(User user) async {
    try {
      // Actualizar última actividad del usuario
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _firebaseService.createOrUpdateUser(updatedUser);
      print('✅ [Sync] Usuario sincronizado: ${user.email}');
    } catch (e) {
      throw Exception('Error sincronizando usuario: $e');
    }
  }

  // ✅ NUEVA IMPLEMENTACIÓN: Sincronización bidireccional completa de hábitos
  Future<void> _syncHabitsWithBidirectionalMerge(String userId) async {
    try {
      print('🔄 [Sync] === SINCRONIZACIÓN BIDIRECCIONAL DE HÁBITOS ===');
      
      // PASO 1: Obtener datos locales
      final localHabits = await _habitDataSource.getAllHabits();
      print('📱 [Sync] Hábitos locales encontrados: ${localHabits.length}');
      
      // PASO 2: Subir hábitos locales a Firebase
      if (localHabits.isNotEmpty) {
        final habitsData = localHabits.map((habit) => {
          'id': habit.id,
          'name': habit.name,
          'created_at': habit.createdAt.toIso8601String(),
          'is_active': habit.isActive ? 1 : 0,
        }).toList();
        
        await _firebaseService.syncHabits(userId, habitsData);
        print('⬆️ [Sync] ${localHabits.length} hábitos subidos a Firebase');
      }
      
      // PASO 3: Descargar hábitos remotos de Firebase
      final remoteHabits = await _firebaseService.getHabits(userId);
      print('☁️ [Sync] Hábitos remotos encontrados: ${remoteHabits.length}');
      
      // PASO 4: ✅ MERGE BIDIRECCIONAL: Aplicar hábitos remotos que no existen localmente
      int newHabitsAdded = 0;
      int conflictsResolved = 0;
      
      for (final remoteHabit in remoteHabits) {
        final remoteId = remoteHabit['id'] as int?;
        final remoteName = remoteHabit['name'] as String? ?? '';
        final remoteCreatedAt = remoteHabit['created_at'] as String? ?? DateTime.now().toIso8601String();
        final remoteIsActive = (remoteHabit['is_active'] as int? ?? 1) == 1;
        
        if (remoteId == null || remoteName.isEmpty) {
          print('⚠️ [Sync] Hábito remoto inválido, saltando...');
          continue;
        }
        
        // Verificar si el hábito ya existe localmente
        final localHabit = localHabits.where((local) => local.id == remoteId).firstOrNull;
        
        if (localHabit == null) {
          // ✅ NUEVO HÁBITO: No existe localmente, agregarlo
          if (remoteIsActive) {
            try {
              final newHabit = HabitModel(
                id: remoteId,
                name: remoteName,
                createdAt: DateTime.parse(remoteCreatedAt),
                isActive: remoteIsActive,
              );
              
              await _habitDataSource.insertHabitWithId(newHabit);
              newHabitsAdded++;
              print('➕ [Sync] Nuevo hábito agregado desde remoto: "$remoteName" (ID: $remoteId)');
            } catch (e) {
              print('❌ [Sync] Error agregando hábito remoto "$remoteName": $e');
            }
          }
        } else {
          // ✅ RESOLUCIÓN DE CONFLICTOS: Hábito existe, verificar diferencias
          bool needsUpdate = false;
          HabitModel updatedHabit = localHabit;
          
          // Comparar y resolver conflictos
          if (localHabit.name != remoteName) {
            print('🔀 [Sync] Conflicto de nombre en hábito ID $remoteId: Local="${localHabit.name}" vs Remoto="$remoteName"');
            // Estrategia: Mantener el nombre más reciente (remoto en este caso)
            updatedHabit = updatedHabit.copyWith(name: remoteName);
            needsUpdate = true;
          }
          
          if (localHabit.isActive != remoteIsActive) {
            print('🔀 [Sync] Conflicto de estado en hábito ID $remoteId: Local=${localHabit.isActive} vs Remoto=$remoteIsActive');
            // Estrategia: Priorizar activación (si cualquiera está activo, mantener activo)
            final resolvedIsActive = localHabit.isActive || remoteIsActive;
            updatedHabit = updatedHabit.copyWith(isActive: resolvedIsActive);
            needsUpdate = true;
          }
          
          if (needsUpdate) {
            try {
              await _habitDataSource.updateHabit(updatedHabit);
              conflictsResolved++;
              print('🔄 [Sync] Conflicto resuelto para hábito "$remoteName" (ID: $remoteId)');
            } catch (e) {
              print('❌ [Sync] Error resolviendo conflicto para hábito ID $remoteId: $e');
            }
          }
        }
      }
      
      print('✅ [Sync] Hábitos sincronizados exitosamente:');
      print('   📱 Local: ${localHabits.length}');
      print('   ☁️ Remoto: ${remoteHabits.length}');
      print('   ➕ Nuevos agregados: $newHabitsAdded');
      print('   🔄 Conflictos resueltos: $conflictsResolved');
      
    } catch (e) {
      throw Exception('Error en sincronización bidireccional de hábitos: $e');
    }
  }

  // ✅ NUEVA IMPLEMENTACIÓN: Sincronización bidireccional completa de entradas
  Future<void> _syncHabitEntriesWithBidirectionalMerge(String userId) async {
    try {
      print('🔄 [Sync] === SINCRONIZACIÓN BIDIRECCIONAL DE ENTRADAS ===');
      
      // PASO 1: Obtener entradas locales (últimos 30 días)
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final localEntries = await _habitDataSource.getHabitEntriesForDateRange(startDate, now);
      
      // Filtrar solo entradas que existen en BD (no auto-skip)
      final realLocalEntries = localEntries.where((entry) => entry.id != null).toList();
      print('📱 [Sync] Entradas locales reales encontradas: ${realLocalEntries.length}');
      
      // PASO 2: Subir entradas locales a Firebase
      if (realLocalEntries.isNotEmpty) {
        final entriesData = realLocalEntries.map((entry) => {
          'habit_id': entry.habitId,
          'date': entry.date.toIso8601String().split('T')[0], // Solo YYYY-MM-DD
          'status': entry.status.index,
          'id': entry.id,
        }).toList();
        
        await _firebaseService.syncHabitEntries(userId, entriesData);
        print('⬆️ [Sync] ${realLocalEntries.length} entradas subidas a Firebase');
      }
      
      // PASO 3: Descargar entradas remotas de Firebase (últimos 30 días)
      final remoteEntries = await _firebaseService.getHabitEntries(userId, since: startDate);
      print('☁️ [Sync] Entradas remotas encontradas: ${remoteEntries.length}');
      
      // PASO 4: ✅ MERGE BIDIRECCIONAL: Aplicar entradas remotas
      int newEntriesAdded = 0;
      int conflictsResolved = 0;
      
      for (final remoteEntry in remoteEntries) {
        final remoteHabitId = remoteEntry['habit_id'] as int?;
        final remoteDateStr = remoteEntry['date'] as String?;
        final remoteStatusInt = remoteEntry['status'] as int?;
        
        if (remoteHabitId == null || remoteDateStr == null || remoteStatusInt == null) {
          print('⚠️ [Sync] Entrada remota inválida, saltando...');
          continue;
        }
        
        try {
          final remoteDate = DateTime.parse(remoteDateStr);
          final remoteStatus = HabitStatus.values[remoteStatusInt];
          
          // Verificar si la entrada ya existe localmente
          final existingLocalEntry = await _habitDataSource.getHabitEntryForDate(remoteHabitId, remoteDate);
          
          if (existingLocalEntry == null || existingLocalEntry.id == null) {
            // ✅ NUEVA ENTRADA: No existe localmente, agregarla
            try {
              final newEntry = HabitEntryModel(
                habitId: remoteHabitId,
                date: remoteDate,
                status: remoteStatus,
              );
              
              await _habitDataSource.insertHabitEntry(newEntry);
              newEntriesAdded++;
              print('➕ [Sync] Nueva entrada agregada: Hábito $remoteHabitId - ${remoteDateStr} - ${remoteStatus.name}');
            } catch (e) {
              print('❌ [Sync] Error agregando entrada remota: $e');
            }
          } else {
            // ✅ RESOLUCIÓN DE CONFLICTOS: Entrada existe, verificar diferencias
            if (existingLocalEntry.status != remoteStatus) {
              print('🔀 [Sync] Conflicto de estado en entrada: Hábito $remoteHabitId - $remoteDateStr');
              print('    Local: ${existingLocalEntry.status.name} vs Remoto: ${remoteStatus.name}');
              
              // Estrategia: Priorizar completed > skipped > pending
              HabitStatus resolvedStatus = _resolveStatusConflict(existingLocalEntry.status, remoteStatus);
              
              if (resolvedStatus != existingLocalEntry.status) {
                try {
                  final updatedEntry = HabitEntryModel(
                    id: existingLocalEntry.id,
                    habitId: remoteHabitId,
                    date: remoteDate,
                    status: resolvedStatus,
                  );
                  
                  await _habitDataSource.updateHabitEntry(updatedEntry);
                  conflictsResolved++;
                  print('🔄 [Sync] Conflicto resuelto: Hábito $remoteHabitId - $remoteDateStr -> ${resolvedStatus.name}');
                } catch (e) {
                  print('❌ [Sync] Error resolviendo conflicto de entrada: $e');
                }
              }
            }
          }
        } catch (e) {
          print('❌ [Sync] Error procesando entrada remota: $e');
        }
      }
      
      print('✅ [Sync] Entradas sincronizadas exitosamente:');
      print('   📱 Local: ${realLocalEntries.length}');
      print('   ☁️ Remoto: ${remoteEntries.length}');
      print('   ➕ Nuevas agregadas: $newEntriesAdded');
      print('   🔄 Conflictos resueltos: $conflictsResolved');
      
    } catch (e) {
      throw Exception('Error en sincronización bidireccional de entradas: $e');
    }
  }

  // ✅ NUEVA: Estrategia de resolución de conflictos para estados de hábitos
  HabitStatus _resolveStatusConflict(HabitStatus local, HabitStatus remote) {
    // Prioridad: completed > skipped > pending
    const priority = {
      HabitStatus.completed: 3,
      HabitStatus.skipped: 2,
      HabitStatus.pending: 1,
    };
    
    final localPriority = priority[local] ?? 0;
    final remotePriority = priority[remote] ?? 0;
    
    return localPriority >= remotePriority ? local : remote;
  }

  /// Sync manual solo para hábitos
  Future<bool> syncHabitsOnly() async {
    final user = _authService.currentUser;
    if (user == null || user.isGuest) return false;

    try {
      _setIsSyncing(true);
      _syncStatusController.add(SyncStatus.syncing);
      
      await _syncHabitsWithBidirectionalMerge(user.id);
      
      _syncStatusController.add(SyncStatus.completed);
      print('✅ [Sync] Solo hábitos sincronizados');
      return true;
    } catch (e) {
      print('❌ [Sync] Error en sync de hábitos: $e');
      _syncStatusController.add(SyncStatus.failed);
      return false;
    } finally {
      _setIsSyncing(false);
    }
  }

  /// Sync manual solo para entradas
  Future<bool> syncEntriesOnly() async {
    final user = _authService.currentUser;
    if (user == null || user.isGuest) return false;

    try {
      _setIsSyncing(true);
      _syncStatusController.add(SyncStatus.syncing);
      
      await _syncHabitEntriesWithBidirectionalMerge(user.id);
      
      _syncStatusController.add(SyncStatus.completed);
      print('✅ [Sync] Solo entradas sincronizadas');
      return true;
    } catch (e) {
      print('❌ [Sync] Error en sync de entradas: $e');
      _syncStatusController.add(SyncStatus.failed);
      return false;
    } finally {
      _setIsSyncing(false);
    }
  }

  /// Forzar sync inmediato para el Drawer
  Future<void> requestSync() async {
    print('🔄 [Sync] Sincronización solicitada manualmente');
    await syncAll();
  }

  /// Pausar auto-sync (útil para conservar batería)
  void pauseAutoSync() {
    _autoSyncTimer?.cancel();
    print('⏸️ [Sync] Auto-sync pausado');
  }

  /// Reanudar auto-sync
  void resumeAutoSync() {
    _initializeAutoSync();
    print('▶️ [Sync] Auto-sync reanudado');
  }

  // Métodos helper privados para streams
  void _setIsSyncing(bool value) {
    _isSyncing = value;
    _isSyncingController.add(value);
  }

  void _setLastSyncTime(DateTime? time) {
    _lastSyncTime = time;
    _lastSyncController.add(time);
  }

  Future<void> dispose() async {
    _autoSyncTimer?.cancel();
    await _syncStatusController.close();
    await _lastSyncController.close();
    await _isSyncingController.close();
    print('🧹 [Sync] Sync Manager limpiado');
  }
}