// lib/core/sync/repositories/sync_repository.dart - IMPLEMENTACIÓN COMPLETA
import '../models/sync_models.dart';
import '../services/firebase_service.dart';
import '../services/sync_manager.dart';
import '../../auth/interfaces/i_auth_service.dart';

abstract class SyncRepository {
  Stream<SyncStatus> get syncStatus;
  Stream<bool> get isSyncing;
  Stream<DateTime?> get lastSyncTime;
  
  Future<bool> syncAll();
  Future<bool> syncHabitsOnly();
  Future<bool> syncEntriesOnly();
  Future<void> requestSync();
  
  Future<bool> hasInternetConnection();
  Future<DateTime?> getLastRemoteSync(String collectionType);
  Future<bool> hasConflicts(String collectionType, DateTime localLastSync);
  
  void pauseAutoSync();
  void resumeAutoSync();
}

class SyncRepositoryImpl implements SyncRepository {
  final SyncManager _syncManager;
  final FirebaseService _firebaseService;
  final IAuthService _authService;

  SyncRepositoryImpl({
    required SyncManager syncManager,
    required FirebaseService firebaseService,
    required IAuthService authService,
  }) : _syncManager = syncManager,
       _firebaseService = firebaseService,
       _authService = authService;

  @override
  Stream<SyncStatus> get syncStatus => _syncManager.syncStatus;

  @override
  Stream<bool> get isSyncing => _syncManager.isSyncingStream;

  @override
  Stream<DateTime?> get lastSyncTime => _syncManager.lastSyncTimeStream;

  @override
  Future<bool> syncAll() async {
    try {
      print('🔄 [SyncRepo] Iniciando sincronización completa...');
      final result = await _syncManager.syncAll();
      print('✅ [SyncRepo] Sincronización completa: ${result ? "exitosa" : "fallida"}');
      return result;
    } catch (e) {
      print('❌ [SyncRepo] Error en syncAll: $e');
      return false;
    }
  }

  @override
  Future<bool> syncHabitsOnly() async {
    try {
      print('🔄 [SyncRepo] Iniciando sync solo de hábitos...');
      final result = await _syncManager.syncHabitsOnly();
      print('✅ [SyncRepo] Sync de hábitos: ${result ? "exitoso" : "fallido"}');
      return result;
    } catch (e) {
      print('❌ [SyncRepo] Error en syncHabitsOnly: $e');
      return false;
    }
  }

  @override
  Future<bool> syncEntriesOnly() async {
    try {
      print('🔄 [SyncRepo] Iniciando sync solo de entradas...');
      final result = await _syncManager.syncEntriesOnly();
      print('✅ [SyncRepo] Sync de entradas: ${result ? "exitoso" : "fallido"}');
      return result;
    } catch (e) {
      print('❌ [SyncRepo] Error en syncEntriesOnly: $e');
      return false;
    }
  }

  @override
  Future<void> requestSync() async {
    try {
      print('🔄 [SyncRepo] Sync solicitado manualmente...');
      await _syncManager.requestSync();
      print('✅ [SyncRepo] Sync manual completado');
    } catch (e) {
      print('❌ [SyncRepo] Error en requestSync: $e');
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      return await _firebaseService.hasInternetConnection();
    } catch (e) {
      print('❌ [SyncRepo] Error verificando conexión: $e');
      return false;
    }
  }

  @override
  Future<DateTime?> getLastRemoteSync(String collectionType) async {
    try {
      final user = _authService.currentUser;
      if (user == null || user.isGuest) return null;
      
      return await _firebaseService.getLastSyncTimestamp(user.id, collectionType);
    } catch (e) {
      print('❌ [SyncRepo] Error obteniendo último sync remoto: $e');
      return null;
    }
  }

  @override
  Future<bool> hasConflicts(String collectionType, DateTime localLastSync) async {
    try {
      final user = _authService.currentUser;
      if (user == null || user.isGuest) return false;
      
      return await _firebaseService.hasConflicts(user.id, collectionType, localLastSync);
    } catch (e) {
      print('❌ [SyncRepo] Error verificando conflictos: $e');
      return false;
    }
  }

  @override
  void pauseAutoSync() {
    _syncManager.pauseAutoSync();
    print('⏸️ [SyncRepo] Auto-sync pausado');
  }

  @override
  void resumeAutoSync() {
    _syncManager.resumeAutoSync();
    print('▶️ [SyncRepo] Auto-sync reanudado');
  }
}