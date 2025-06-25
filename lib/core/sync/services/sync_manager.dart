// lib/core/sync/services/sync_manager.dart - MODIFICADO (CONSOLIDACIÓN DE SKIPPED)

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
import '../../../shared/utils/date_utils.dart'; // Importar DateUtils

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
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      final user = _authService.currentUser;
      if (user != null && !user.isGuest && !_isSyncing) {
        syncAll();
      }
    });
  }

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

      final hasConnection = await _firebaseService.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('Sin conexión a internet');
      }

      await _syncUser(user);
      await _syncHabitsWithBidirectionalMerge(user.id);
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
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _firebaseService.createOrUpdateUser(updatedUser);
      print('✅ [Sync] Usuario sincronizado: ${user.email}');
    } catch (e) {
      throw Exception('Error sincronizando usuario: $e');
    }
  }

  Future<void> _syncHabitsWithBidirectionalMerge(String userId) async {
    try {
      print('🔄 [Sync] === SINCRONIZACIÓN BIDIRECCIONAL DE HÁBITOS ===');
      
      final localHabits = await _habitDataSource.getAllHabits(includeInactive: true); 
      print('📱 [Sync] Hábitos locales encontrados: ${localHabits.length}');
      
      if (localHabits.isNotEmpty) {
        final habitsData = localHabits.map((habit) => {
          'id': habit.id,
          'name': habit.name,
          'created_at': habit.createdAt.toIso8601String(),
          'is_active': habit.isActive ? 1 : 0,
        }).toList();
        
        await _firebaseService.syncHabits(userId, habitsData);
        print('⬆️ [Sync] ${habitsData.length} hábitos subidos a Firebase');
      }
      
      final remoteHabits = await _firebaseService.getHabits(userId); 
      print('☁️ [Sync] Hábitos remotos encontrados: ${remoteHabits.length}');
      
      int newHabitsAdded = 0;
      int conflictsResolved = 0;
      
      final Map<int, HabitModel> localHabitsMap = { for (var h in localHabits) h.id!: h };
      
      for (final remoteHabit in remoteHabits) {
        final remoteId = remoteHabit['id'] as int?;
        final remoteName = remoteHabit['name'] as String? ?? '';
        final remoteCreatedAt = remoteHabit['created_at'] as String? ?? DateTime.now().toIso8601String();
        final remoteIsActive = (remoteHabit['is_active'] as int? ?? 1) == 1;
        
        if (remoteId == null || remoteName.isEmpty) {
          print('⚠️ [Sync] Hábito remoto inválido, saltando...');
          continue;
        }
        
        final localHabit = localHabitsMap[remoteId];
        
        if (localHabit == null) {
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
          } else {
            print('ℹ️ [Sync] Hábito remoto $remoteId está inactivo, no se agrega localmente.'); 
          }
        } else {
          bool needsUpdate = false;
          HabitModel updatedHabit = localHabit;
          
          if (localHabit.name != remoteName) {
            print('🔀 [Sync] Conflicto de nombre en hábito ID $remoteId: Local="${localHabit.name}" vs Remoto="$remoteName"');
            updatedHabit = updatedHabit.copyWith(name: remoteName);
            needsUpdate = true;
          }
          
          if (localHabit.isActive != remoteIsActive) {
            print('🔀 [Sync] Conflicto de estado (activo/inactivo) en hábito ID $remoteId: Local=${localHabit.isActive} vs Remoto=$remoteIsActive');
            updatedHabit = updatedHabit.copyWith(isActive: remoteIsActive);
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
      print('   🔄 Conflicto de hábitos resueltos: $conflictsResolved');
      print('   ℹ️ Hábitos remotos inactivos ignorados o actualizados localmente.'); 

    } catch (e) {
      throw Exception('Error en sincronización bidireccional de hábitos: $e');
    }
  }

  // ✅ Sincronización bidireccional completa de entradas - MODIFICADO para usar last_modified y CONSOLIDAR SKIPPED
  Future<void> _syncHabitEntriesWithBidirectionalMerge(String userId) async {
    try {
      print('🔄 [Sync] === SINCRONIZACIÓN BIDIRECCIONAL DE ENTRADAS ===');
      
      // PASO 1: Consolidar entradas 'skipped' para días pasados sin acción
      print('🔄 [Sync] Consolidando entradas "skipped" para días pasados...');
      final allHabits = await _habitDataSource.getAllHabits(includeInactive: false); // Solo hábitos activos
      final today = AppDateUtils.getStartOfDay(DateTime.now());
      int skippedEntriesConsolidated = 0;

      for (final habit in allHabits) {
        // Obtenemos las entradas de este hábito desde su creación hasta ayer
        final entriesForHabit = await _habitDataSource.getHabitEntriesForDateRange(
          AppDateUtils.getStartOfDay(habit.createdAt), 
          today.subtract(const Duration(days: 1)), // Hasta ayer
        );
        final existingDatesForHabit = entriesForHabit.map((e) => AppDateUtils.getStartOfDay(e.date)).toSet();

        // Iteramos desde la creación del hábito hasta ayer
        DateTime currentDate = AppDateUtils.getStartOfDay(habit.createdAt);
        while (currentDate.isBefore(today)) {
          if (!existingDatesForHabit.contains(currentDate)) {
            // No existe entrada para este hábito en esta fecha pasada
            final newSkippedEntry = HabitEntryModel(
              habitId: habit.id!,
              date: currentDate,
              status: HabitStatus.skipped,
              lastModified: DateTime.now(), // Timestamp del momento de la consolidación
            );
            await _habitDataSource.insertHabitEntry(newSkippedEntry);
            skippedEntriesConsolidated++;
            print('➕ [Sync] Consolidada entrada "skipped" para Hábito ${habit.id} en ${currentDate.toIso8601String().split('T')[0]}');
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
      print('✅ [Sync] Consolidación de "skipped" completada. ${skippedEntriesConsolidated} entradas añadidas.');

      // PASO 2: Obtener todas las entradas locales (incluidas las nuevas 'skipped')
      final latestLocalEntries = await _habitDataSource.getHabitEntriesForDateRange(
        AppDateUtils.getStartOfDay(DateTime.now().subtract(const Duration(days: 365))), // Puedes ajustar el rango si es necesario
        AppDateUtils.getEndOfDay(DateTime.now()),
      );
      
      final Map<String, HabitEntryModel> localEntriesMap = {
        for (var entry in latestLocalEntries.where((e) => e.id != null))
          '${entry.habitId}_${entry.date.toIso8601String().split('T')[0]}': entry
      };
      print('📱 [Sync] Entradas locales reales encontradas: ${localEntriesMap.length}');
      
      // PASO 3: Subir entradas locales a Firebase
      if (localEntriesMap.isNotEmpty) {
        final entriesData = localEntriesMap.values.map((entry) => {
          'habit_id': entry.habitId,
          'date': entry.date.toIso8601String().split('T')[0],
          'status': entry.status.index,
          'id': entry.id,
          'last_modified': entry.lastModified?.toIso8601String(), // Enviar el last_modified local
        }).toList();
        
        await _firebaseService.syncHabitEntries(userId, entriesData);
        print('⬆️ [Sync] ${entriesData.length} entradas subidas a Firebase');
      }
      
      // PASO 4: Descargar entradas remotas de Firebase (rango amplio para cubrir inactivos también)
      // Descargamos entradas de un rango más amplio para asegurar que se capturen todas las actualizaciones
      final remoteEntries = await _firebaseService.getHabitEntries(
        userId, 
        since: AppDateUtils.getStartOfDay(DateTime.now().subtract(const Duration(days: 365))), // Puedes ajustar el rango
      );
      print('☁️ [Sync] Entradas remotas encontradas: ${remoteEntries.length}');
      
      // PASO 5: MERGE BIDIRECCIONAL: Aplicar entradas remotas
      int newEntriesAdded = 0;
      int conflictsResolved = 0;
      
      for (final remoteEntry in remoteEntries) {
        final remoteHabitId = remoteEntry['habit_id'] as int?;
        final remoteDateStr = remoteEntry['date'] as String?;
        final remoteStatusInt = remoteEntry['status'] as int?;
        final remoteLastModifiedStr = remoteEntry['last_modified'] as String?; 
        
        if (remoteHabitId == null || remoteDateStr == null || remoteStatusInt == null) {
          print('⚠️ [Sync] Entrada remota inválida, saltando...');
          continue;
        }
        
        try {
          final remoteDate = DateTime.parse(remoteDateStr);
          final remoteStatus = HabitStatus.values[remoteStatusInt];
          final remoteLastModified = remoteLastModifiedStr != null ? DateTime.parse(remoteLastModifiedStr) : null;
          
          final entryKey = '${remoteHabitId}_${remoteDateStr}';
          final existingLocalEntry = localEntriesMap[entryKey];
          
          if (existingLocalEntry == null || existingLocalEntry.id == null) {
            // NUEVA ENTRADA: No existe localmente, agregarla
            // Solo insertamos si la entrada remota tiene un timestamp válido y no es estado 'pending' por defecto
            if (remoteLastModified != null && remoteStatus != HabitStatus.pending) { 
              try {
                final newEntry = HabitEntryModel(
                  habitId: remoteHabitId,
                  date: remoteDate,
                  status: remoteStatus,
                  id: remoteEntry['entry_id'], // ID de Firebase, se puede usar si quieres mantener el mismo ID entre BDs
                  lastModified: remoteLastModified,
                );
                
                await _habitDataSource.insertHabitEntry(newEntry);
                newEntriesAdded++;
                print('➕ [Sync] Nueva entrada agregada desde remoto: Hábito $remoteHabitId - ${remoteDateStr} - ${remoteStatus.name}');
              } catch (e) {
                print('❌ [Sync] Error agregando entrada remota: $e');
              }
            } else {
              print('ℹ️ [Sync] Entrada remota $entryKey con estado ${remoteStatus.name} o sin timestamp, no se agrega localmente.');
            }
          } else {
            // RESOLUCIÓN DE CONFLICTOS: Entrada existe localmente, verificar diferencias
            final localLastModified = existingLocalEntry.lastModified;

            // Si los estados son diferentes
            if (existingLocalEntry.status != remoteStatus) {
                // Comparamos los timestamps para ver cuál es más reciente
                if (localLastModified == null || (remoteLastModified != null && remoteLastModified.isAfter(localLastModified))) {
                    // Remoto es más reciente o local no tiene timestamp: Remoto gana
                    print('🔀 [Sync] Conflicto de estado resuelto por timestamp más reciente (remoto gana): Hábito $remoteHabitId - $remoteDateStr. Local:${existingLocalEntry.status.name} (${localLastModified?.toIso8601String() ?? 'null'}) vs Remoto:${remoteStatus.name} (${remoteLastModified?.toIso8601String() ?? 'null'})');
                    final updatedEntry = existingLocalEntry.copyWith(
                      status: remoteStatus, // El estado remoto (más reciente) gana
                      lastModified: remoteLastModified,
                    );
                    await _habitDataSource.updateHabitEntry(updatedEntry);
                    conflictsResolved++;
                } else {
                    // Local es más reciente: Local gana (no hace falta actualizar porque ya lo tiene)
                    print('🔀 [Sync] Conflicto de estado resuelto por timestamp más reciente (local gana): Hábito $remoteHabitId - $remoteDateStr. Local:${existingLocalEntry.status.name} (${localLastModified?.toIso8601String() ?? 'null'}) vs Remoto:${remoteStatus.name} (${remoteLastModified?.toIso8601String() ?? 'null'})');
                }
            } else {
              // Los estados son iguales, pero actualizamos el timestamp local si el remoto es más reciente
              if (localLastModified == null || (remoteLastModified != null && remoteLastModified.isAfter(localLastModified))) {
                 final updatedEntry = existingLocalEntry.copyWith(lastModified: remoteLastModified);
                 if (updatedEntry != existingLocalEntry) { 
                    await _habitDataSource.updateHabitEntry(updatedEntry);
                 }
              }
            }
          }
        } catch (e) {
          print('❌ [Sync] Error procesando entrada remota: $e');
        }
      }
      
      print('✅ [Sync] Entradas sincronizadas exitosamente:');
      print('   📱 Local: ${localEntriesMap.length}');
      print('   ☁️ Remoto: ${remoteEntries.length}');
      print('   ➕ Nuevas agregadas: $newEntriesAdded');
      print('   🔄 Conflictos resueltos: $conflictsResolved');
      
    } catch (e) {
      throw Exception('Error en sincronización bidireccional de entradas: $e');
    }
  }

  // Estrategia de resolución de conflictos para estados de hábitos
  HabitStatus _resolveStatusConflict(HabitStatus local, HabitStatus remote) {
    const priority = {
      HabitStatus.completed: 3,
      HabitStatus.skipped: 2,
      HabitStatus.pending: 1,
    };
    
    final localPriority = priority[local] ?? 0;
    final remotePriority = priority[remote] ?? 0;
    
    return localPriority >= remotePriority ? local : remote;
  }

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

  Future<void> requestSync() async {
    print('🔄 [Sync] Sincronización solicitada manualmente');
    await syncAll();
  }

  void pauseAutoSync() {
    _autoSyncTimer?.cancel();
    print('⏸️ [Sync] Auto-sync pausado');
  }

  void resumeAutoSync() {
    _initializeAutoSync();
    print('▶️ [Sync] Auto-sync reanudado');
  }

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