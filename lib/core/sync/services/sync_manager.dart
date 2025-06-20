// lib/core/sync/services/sync_manager.dart
import 'dart:async';
import '../services/firebase_service.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';

class SyncManager {
  final FirebaseService _firebaseService;
  final AuthService _authService;
  
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Stream controllers para estado de sync
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  final _lastSyncController = StreamController<DateTime?>.broadcast();
  
  // ✅ NUEVOS: Stream controllers para el Drawer
  final _isSyncingController = StreamController<bool>.broadcast();

  SyncManager({
    required FirebaseService firebaseService,
    required AuthService authService,
  }) : _firebaseService = firebaseService,
       _authService = authService {
    _initializeAutoSync();
  }

  // Streams públicos
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;
  Stream<DateTime?> get lastSyncTime => _lastSyncController.stream;
  
  // ✅ NUEVOS: Streams para el Drawer
  Stream<bool> get isSyncingStream => _isSyncingController.stream;
  Stream<DateTime?> get lastSyncTimeStream => _lastSyncController.stream; // Reutilizar
  
  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSyncTime;

  void _initializeAutoSync() {
    // Auto-sync cada 30 minutos si hay usuario logueado
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      final user = _authService.currentUser;
      if (user != null && !_isSyncing) {
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

    if (_isSyncing) {
      print('⚠️ [Sync] Ya hay sincronización en progreso');
      return false;
    }

    try {
      // ✅ ACTUALIZADO: Notificar inicio de sync
      _setIsSyncing(true);
      _syncStatusController.add(SyncStatus.syncing);
      
      print('🔄 [Sync] Iniciando sincronización completa...');

      // 1. Verificar conectividad
      final hasConnection = await _firebaseService.hasInternetConnection();
      if (!hasConnection) {
        throw Exception('Sin conexión a internet');
      }

      // 2. Sincronizar usuario
      await _syncUser(user);

      // 3. Sincronizar hábitos (implementar según datasources)
      // await _syncHabits(user.id);

      // 4. Sincronizar entradas (implementar según datasources)
      // await _syncHabitEntries(user.id);

      // ✅ ACTUALIZADO: Actualizar timestamps
      _setLastSyncTime(DateTime.now());
      _syncStatusController.add(SyncStatus.completed);

      print('✅ [Sync] Sincronización completada');
      return true;

    } catch (e) {
      print('❌ [Sync] Error: $e');
      _syncStatusController.add(SyncStatus.failed);
      rethrow; // ✅ NUEVO: Re-lanzar para que el Drawer maneje el error
    } finally {
      // ✅ ACTUALIZADO: Notificar fin de sync
      _setIsSyncing(false);
    }
  }

  Future<void> _syncUser(AppUser user) async {
    try {
      // Actualizar última actividad del usuario
      final updatedUser = user.copyWith(lastLogin: DateTime.now());
      await _firebaseService.createOrUpdateUser(updatedUser);
      print('✅ [Sync] Usuario sincronizado');
    } catch (e) {
      throw Exception('Error sincronizando usuario: $e');
    }
  }

  /// Sync manual solo para hábitos
  Future<bool> syncHabitsOnly() async {
    // TODO: Implementar cuando tengamos acceso a habit datasource
    print('🔄 [Sync] Sincronización de hábitos (TODO)');
    return true;
  }

  /// Sync manual solo para entradas
  Future<bool> syncEntriesOnly() async {
    // TODO: Implementar cuando tengamos acceso a entries datasource
    print('🔄 [Sync] Sincronización de entradas (TODO)');
    return true;
  }

  /// ✅ ACTUALIZADO: Forzar sync inmediato para el Drawer
  Future<void> requestSync() async {
    await syncAll(); // Cambiar a await para manejar errores
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

  // ✅ NUEVOS: Métodos helper privados para streams
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
    // ✅ NUEVO: Cerrar nuevo stream
    await _isSyncingController.close();
    print('🧹 [Sync] Sync Manager limpiado');
  }
}

// ✅ NUEVO: Enum para estados de sync si no existe
enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
  conflict,
}