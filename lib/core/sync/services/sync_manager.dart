// lib/core/sync/services/sync_manager.dart
import 'dart:async';
import 'package:habitiurs/core/sync/services/firebase_service.dart';
import '../../auth/interfaces/i_auth_service.dart';
import '../../auth/models/user.dart';
import '../models/sync_models.dart';

// Imports para acceso a datasources (asegúrate de que estén correctos)
import '../../../features/habits/data/datasources/habit_local_datasource.dart';
import '../../../features/statistics/data/datasources/statistics_local_datasource.dart';
import '../../../features/habits/data/models/habit_model.dart';
import '../../../features/habits/domain/entities/habit.dart';
import '../../../features/habits/data/models/habit_entry_model.dart';
import '../../../shared/enums/habit_status.dart';
import '../../../shared/utils/date_utils.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class SyncManager {
  final FirebaseService _firebaseService;
  final IAuthService _authService;
  final HabitLocalDataSource _habitDataSource;
  final StatisticsLocalDatasource _statisticsDataSource;

  // Aquí es donde se declara y gestiona el temporizador
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
    _initializeAutoSync(); // Se llama aquí para iniciar el temporizador
  }

  // Streams públicos
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  Stream<DateTime?> get lastSyncTime => _lastSyncController.stream;
  Stream<bool> get isSyncingStream => _isSyncingController.stream;
  Stream<DateTime?> get lastSyncTimeStream => _lastSyncController.stream;

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSyncTime;

  // Método para inicializar el temporizador de auto-sincronización
  void _initializeAutoSync() {
    _autoSyncTimer
        ?.cancel(); // Se cancela cualquier temporizador existente primero

    // Ejecutar consolidación inicial al arrancar (si hay usuario)
    final currentUser = _authService.currentUser;
    if (currentUser != null && !currentUser.isGuest) {
      _consolidateHabitHistory();
    }

    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      final user = _authService.currentUser;
      if (user != null && !user.isGuest) {
        // 1. Siempre intentar consolidar historial localmente primero (funciona offline)
        await _consolidateHabitHistory();

        // 2. Si no hay sync en progreso, intentar sync con nube
        if (!_isSyncing) {
          syncAll().catchError((e) {
            appLog('⚠️ [SyncManager] Error en auto-sync: $e');
            return false;
          });
        }
      }
    });
    appLog('▶️ [SyncManager] Auto-sync inicializado o reanudado.');
  }

  Future<void> _consolidateHabitHistory() async {
    try {
      appLog(
        '🔄 [SyncManager] Consolidando entradas "skipped" para días pasados (LOCAL)...',
      );
      final allHabits = await _habitDataSource.getAllHabits(
        includeInactive: false,
      );
      final today = AppDateUtils.getStartOfDay(DateTime.now());
      int skippedEntriesConsolidated = 0;

      for (final habit in allHabits) {
        // Obtenemos las entradas de este hábito desde su creación hasta ayer
        final entriesForHabit = await _habitDataSource
            .getHabitEntriesForDateRange(
              AppDateUtils.getStartOfDay(habit.createdAt),
              today.subtract(const Duration(days: 1)), // Hasta ayer
            );
        final existingDatesForHabit =
            entriesForHabit
                .map((e) => AppDateUtils.getStartOfDay(e.date))
                .toSet();

        // Iteramos desde la creación del hábito hasta ayer
        DateTime currentDate = AppDateUtils.getStartOfDay(habit.createdAt);
        while (currentDate.isBefore(today)) {
          // Los días no programados para este hábito no cuentan como omitidos
          if (!habit.isScheduledOn(currentDate)) {
            currentDate = currentDate.add(const Duration(days: 1));
            continue;
          }
          if (!existingDatesForHabit.contains(currentDate)) {
            // No existe entrada para este hábito en esta fecha pasada
            final newSkippedEntry = HabitEntryModel(
              habitId: habit.id!,
              date: currentDate,
              status: HabitStatus.skipped,
              lastModified:
                  DateTime.now(), // Timestamp del momento de la consolidación
            );
            await _habitDataSource.insertHabitEntry(newSkippedEntry);
            skippedEntriesConsolidated++;
            appLog(
              '➕ [SyncManager] Consolidada entrada "skipped" para Hábito ${habit.id} en ${currentDate.toIso8601String().split('T')[0]}',
            );
          }
          currentDate = currentDate.add(const Duration(days: 1));
        }
      }
      if (skippedEntriesConsolidated > 0) {
        appLog(
          '✅ [SyncManager] Consolidación de "skipped" completada. ${skippedEntriesConsolidated} entradas añadidas localmente.',
        );
      }
    } catch (e) {
      appLog('❌ [SyncManager] Error en consolidación de historial local: $e');
    }
  }

  Future<bool> syncAll() async {
    final user = _authService.currentUser;
    if (user == null) {
      appLog('⚠️ [SyncManager] No hay usuario logueado');
      return false;
    }

    if (user.isGuest) {
      appLog('⚠️ [SyncManager] Usuario invitado - sync no disponible');
      return false;
    }

    if (_isSyncing) {
      appLog('⚠️ [SyncManager] Ya hay sincronización en progreso');
      return false;
    }

    try {
      _setIsSyncing(true);
      _syncStatusController.add(SyncStatus.syncing);
      appLog(
        '🔄 [SyncManager] Iniciando sincronización completa para usuario: ${user.email}',
      );

      // Asegurar que la data local esté "rellena" antes de subir
      await _consolidateHabitHistory();

      final hasConnection = await _firebaseService.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('Sin conexión a internet');
      }

      // User sync is non-critical: quota/network failure shouldn't abort habit download
      try {
        await _syncUser(user);
      } catch (e) {
        _logSyncError('User sync', e);
      }

      await _syncHabitsWithBidirectionalMerge(user.id);

      // Entry sync is non-critical: failure should not prevent showing downloaded habits
      try {
        await _syncHabitEntriesWithBidirectionalMerge(user.id);
      } catch (e) {
        _logSyncError('Entry sync', e);
      }

      _setLastSyncTime(DateTime.now());
      _syncStatusController.add(SyncStatus.completed);

      appLog('✅ [SyncManager] Sincronización completada exitosamente');
      return true;
    } catch (e) {
      appLog('❌ [SyncManager] Error: $e');
      _syncStatusController.add(SyncStatus.failed);
      rethrow; // Se relanza la excepción para que el repositorio la capture
    } finally {
      _setIsSyncing(false);
    }
  }

  Future<void> _syncUser(User user) async {
    try {
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _firebaseService.createOrUpdateUser(updatedUser);
      appLog('✅ [SyncManager] Usuario sincronizado: ${user.email}');
    } catch (e) {
      throw Exception('Error sincronizando usuario: $e');
    }
  }

  Future<void> _syncHabitsWithBidirectionalMerge(String userId) async {
    try {
      appLog(
        '🔄 [SyncManager] === SINCRONIZACIÓN BIDIRECCIONAL DE HÁBITOS ===',
      );
      final localHabits = await _habitDataSource.getAllHabits(
        includeInactive: true,
      );
      appLog(
        '📱 [SyncManager] Hábitos locales encontrados: ${localHabits.length}',
      );
      if (localHabits.isNotEmpty) {
        final habitsData =
            localHabits.map((habit) => habit.toFirestoreMap()).toList();
        await _firebaseService.syncHabits(userId, habitsData);
        appLog(
          '⬆️ [SyncManager] ${habitsData.length} hábitos subidos a Firebase',
        );
      }

      final remoteHabits = await _firebaseService.getHabits(userId);
      appLog(
        '☁️ [SyncManager] Hábitos remotos encontrados: ${remoteHabits.length}',
      );

      int newHabitsAdded = 0;
      int conflictsResolved = 0;
      final Map<int, HabitModel> localHabitsMap = {
        for (var h in localHabits) h.id!: h,
      };
      for (final remoteHabit in remoteHabits) {
        final remoteId = remoteHabit['id'] as int?;
        final remoteName = remoteHabit['name'] as String? ?? '';
        final remoteCreatedAt =
            remoteHabit['created_at'] as String? ??
            DateTime.now().toIso8601String();
        final remoteIsActive = (remoteHabit['is_active'] as int? ?? 1) == 1;
        if (remoteId == null || remoteName.isEmpty) {
          appLog('⚠️ [SyncManager] Hábito remoto inválido, saltando...');
          continue;
        }

        final remoteColor = remoteHabit['color'] as int?;
        final remoteIcon = remoteHabit['icon'] as String?;
        final remoteWeekdays = HabitModel.parseWeekdays(
          remoteHabit['weekdays'],
        );
        final remoteReminder = remoteHabit['reminder_time'] as String?;

        final localHabit = localHabitsMap[remoteId];
        if (localHabit == null) {
          if (remoteIsActive) {
            try {
              final newHabit = HabitModel(
                id: remoteId,
                name: remoteName,
                createdAt: DateTime.parse(remoteCreatedAt),
                isActive: remoteIsActive,
                colorValue: remoteColor ?? Habit.defaultColor,
                iconKey: remoteIcon ?? Habit.defaultIcon,
                weekdays: remoteWeekdays,
                reminderTime: remoteReminder,
              );
              await _habitDataSource.insertHabitWithId(newHabit);
              newHabitsAdded++;
              appLog(
                '➕ [SyncManager] Nuevo hábito agregado desde remoto: "$remoteName" (ID: $remoteId)',
              );
            } catch (e) {
              appLog(
                '❌ [SyncManager] Error agregando hábito remoto "$remoteName": $e',
              );
            }
          } else {
            appLog(
              'ℹ️ [SyncManager] Hábito remoto $remoteId está inactivo, no se agrega localmente.',
            );
          }
        } else {
          bool needsUpdate = false;
          HabitModel updatedHabit = localHabit;

          if (localHabit.name != remoteName) {
            appLog(
              '🔀 [SyncManager] Conflicto de nombre en hábito ID $remoteId: Local="${localHabit.name}" vs Remoto="$remoteName"',
            );
            updatedHabit = updatedHabit.copyWithModel(name: remoteName);
            needsUpdate = true;
          }

          if (localHabit.isActive != remoteIsActive) {
            appLog(
              '🔀 [SyncManager] Conflicto de estado (activo/inactivo) en hábito ID $remoteId: Local=${localHabit.isActive} vs Remoto=$remoteIsActive',
            );
            updatedHabit = updatedHabit.copyWithModel(isActive: remoteIsActive);
            needsUpdate = true;
          }

          if (needsUpdate) {
            try {
              await _habitDataSource.updateHabit(updatedHabit);
              conflictsResolved++;
              appLog(
                '🔄 [SyncManager] Conflicto resuelto para hábito "$remoteName" (ID: $remoteId)',
              );
            } catch (e) {
              appLog(
                '❌ [SyncManager] Error resolviendo conflicto para hábito ID $remoteId: $e',
              );
            }
          }
        }
      }

      appLog('✅ [SyncManager] Hábitos sincronizados exitosamente:');
      appLog('   📱 Local: ${localHabits.length}');
      appLog('   ☁️ Remoto: ${remoteHabits.length}');
      appLog('   ➕ Nuevos agregados: $newHabitsAdded');
      appLog('   🔄 Conflicto de hábitos resueltos: $conflictsResolved');
      appLog(
        '   ℹ️ Hábitos remotos inactivos ignorados o actualizados localmente.',
      );
    } catch (e) {
      throw Exception('Error en sincronización bidireccional de hábitos: $e');
    }
  }

  Future<void> _syncHabitEntriesWithBidirectionalMerge(String userId) async {
    try {
      appLog(
        '🔄 [SyncManager] === SINCRONIZACIÓN BIDIRECCIONAL DE ENTRADAS ===',
      );

      // PASO 1 (Mofidicado): Consolidación ya se hace al inicio del syncAll,
      // pero por seguridad también se puede dejar/revisar aquí si se considera necesario.
      // Dado que syncAll llama a _consolidateHabitHistory(), ya deberíamos tener los "skipped" locales listos.

      // PASO 2: Obtener todas las entradas locales (incluidas las nuevas 'skipped')
      final latestLocalEntries = await _habitDataSource
          .getHabitEntriesForDateRange(
            AppDateUtils.getStartOfDay(
              DateTime.now().subtract(const Duration(days: 365)),
            ),
            AppDateUtils.getEndOfDay(DateTime.now()),
          );
      final Map<String, HabitEntryModel> localEntriesMap = {
        for (var entry in latestLocalEntries.where((e) => e.id != null))
          '${entry.habitId}_${entry.date.toIso8601String().split('T')[0]}':
              entry,
      };
      appLog(
        '📱 [SyncManager] Entradas locales reales encontradas: ${localEntriesMap.length}',
      );

      // PASO 3: Subir entradas locales a Firebase
      if (localEntriesMap.isNotEmpty) {
        final entriesData =
            localEntriesMap.values
                .map(
                  (entry) => {
                    'habit_id': entry.habitId,
                    'date': entry.date.toIso8601String().split('T')[0],
                    'status': entry.status.index,
                    'id': entry.id,
                    'last_modified': entry.lastModified?.toIso8601String(),
                  },
                )
                .toList();

        await _firebaseService.syncHabitEntries(userId, entriesData);
        appLog(
          '⬆️ [SyncManager] ${entriesData.length} entradas subidas a Firebase',
        );
      }

      // PASO 4: Descargar entradas remotas de Firebase
      final remoteEntries = await _firebaseService.getHabitEntries(
        userId,
        since: AppDateUtils.getStartOfDay(
          DateTime.now().subtract(const Duration(days: 365)),
        ),
      );
      appLog(
        '☁️ [SyncManager] Entradas remotas encontradas: ${remoteEntries.length}',
      );

      // PASO 5: MERGE BIDIRECCIONAL: Aplicar entradas remotas
      int newEntriesAdded = 0;
      int conflictsResolved = 0;

      for (final remoteEntry in remoteEntries) {
        final remoteHabitId = remoteEntry['habit_id'] as int?;
        final remoteDateStr = remoteEntry['date'] as String?;
        final remoteStatusInt = remoteEntry['status'] as int?;
        final remoteLastModifiedStr = remoteEntry['last_modified'] as String?;
        if (remoteHabitId == null ||
            remoteDateStr == null ||
            remoteStatusInt == null) {
          appLog('⚠️ [SyncManager] Entrada remota inválida, saltando...');
          continue;
        }

        try {
          final remoteDate = DateTime.parse(remoteDateStr);
          final remoteStatus = HabitStatus.values[remoteStatusInt];
          final remoteLastModified =
              remoteLastModifiedStr != null
                  ? DateTime.parse(remoteLastModifiedStr)
                  : null;

          final entryKey = '${remoteHabitId}_${remoteDateStr}';
          final existingLocalEntry = localEntriesMap[entryKey];

          if (existingLocalEntry == null || existingLocalEntry.id == null) {
            if (remoteLastModified != null &&
                remoteStatus != HabitStatus.pending) {
              try {
                final newEntry = HabitEntryModel(
                  habitId: remoteHabitId,
                  date: remoteDate,
                  status: remoteStatus,
                  id: remoteEntry['entry_id'],
                  lastModified: remoteLastModified,
                );
                await _habitDataSource.insertHabitEntry(newEntry);
                newEntriesAdded++;
                appLog(
                  '➕ [SyncManager] Nueva entrada agregada desde remoto: Hábito $remoteHabitId - ${remoteDateStr} - ${remoteStatus.name}',
                );
              } catch (e) {
                appLog('❌ [SyncManager] Error agregando entrada remota: $e');
              }
            } else {
              appLog(
                'ℹ️ [SyncManager] Entrada remota $entryKey con estado ${remoteStatus.name} o sin timestamp, no se agrega localmente.',
              );
            }
          } else {
            final localLastModified = existingLocalEntry.lastModified;
            if (existingLocalEntry.status != remoteStatus) {
              if (localLastModified == null ||
                  (remoteLastModified != null &&
                      remoteLastModified.isAfter(localLastModified))) {
                appLog(
                  '🔀 [SyncManager] Conflicto de estado resuelto por timestamp más reciente (remoto gana): Hábito $remoteHabitId - $remoteDateStr. Local:${existingLocalEntry.status.name} (${localLastModified?.toIso8601String() ?? 'null'}) vs Remoto:${remoteStatus.name} (${remoteLastModified?.toIso8601String() ?? 'null'})',
                );
                final updatedEntry = existingLocalEntry.copyWith(
                  status: remoteStatus,
                  lastModified: remoteLastModified,
                );
                await _habitDataSource.updateHabitEntry(updatedEntry);
                conflictsResolved++;
              } else {
                appLog(
                  '🔀 [SyncManager] Conflicto de estado resuelto por timestamp más reciente (local gana): Hábito $remoteHabitId - $remoteDateStr. Local:${existingLocalEntry.status.name} (${localLastModified?.toIso8601String() ?? 'null'}) vs Remoto:${remoteStatus.name} (${remoteLastModified?.toIso8601String() ?? 'null'})',
                );
              }
            } else {
              if (localLastModified == null ||
                  (remoteLastModified != null &&
                      remoteLastModified.isAfter(localLastModified))) {
                final updatedEntry = existingLocalEntry.copyWith(
                  lastModified: remoteLastModified,
                );
                if (updatedEntry != existingLocalEntry) {
                  await _habitDataSource.updateHabitEntry(updatedEntry);
                }
              }
            }
          }
        } catch (e) {
          appLog('❌ [SyncManager] Error procesando entrada remota: $e');
        }
      }

      appLog('✅ [SyncManager] Entradas sincronizadas exitosamente:');
      appLog('   📱 Local: ${localEntriesMap.length}');
      appLog('   ☁️ Remoto: ${remoteEntries.length}');
      appLog('   ➕ Nuevas agregadas: $newEntriesAdded');
      appLog('   🔄 Conflictos resueltos: $conflictsResolved');
    } catch (e) {
      throw Exception('Error en sincronización bidireccional de entradas: $e');
    }
  }

  Future<bool> syncHabitsOnly() async {
    final user = _authService.currentUser;
    if (user == null || user.isGuest) return false;

    try {
      _setIsSyncing(true);
      _syncStatusController.add(SyncStatus.syncing);

      await _syncHabitsWithBidirectionalMerge(user.id);

      _syncStatusController.add(SyncStatus.completed);
      appLog('✅ [SyncManager] Solo hábitos sincronizados');
      return true;
    } catch (e) {
      appLog('❌ [SyncManager] Error en sync de hábitos: $e');
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

      await _consolidateHabitHistory(); // Ensure local consistency before syncing
      await _syncHabitEntriesWithBidirectionalMerge(user.id);

      _syncStatusController.add(SyncStatus.completed);
      appLog('✅ [SyncManager] Solo entradas sincronizadas');
      return true;
    } catch (e) {
      appLog('❌ [SyncManager] Error en sync de entradas: $e');
      _syncStatusController.add(SyncStatus.failed);
      return false;
    } finally {
      _setIsSyncing(false);
    }
  }

  Future<void> requestSync() async {
    appLog('🔄 [SyncManager] Sincronización solicitada manualmente');
    await syncAll();
  }

  // Métodos para pausar y reanudar el auto-sync, controlados por el temporizador aquí
  void pauseAutoSync() {
    _autoSyncTimer?.cancel();
    appLog('⏸️ [SyncManager] Auto-sync pausado');
  }

  void resumeAutoSync() {
    _initializeAutoSync(); // Re-inicializa el temporizador
    appLog('▶️ [SyncManager] Auto-sync reanudado');
  }

  void _logSyncError(String step, Object e) {
    final msg = e.toString();
    if (msg.contains('RESOURCE_EXHAUSTED') || msg.contains('Quota exceeded')) {
      appLog(
        '🚫 [SyncManager] $step fallido — cuota de Firestore agotada (se renueva en 24 h): $e',
      );
    } else {
      appLog('⚠️ [SyncManager] $step fallido, continuando: $e');
    }
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
    appLog('🧹 [SyncManager] Sync Manager limpiado');
  }
}
