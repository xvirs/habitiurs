// lib/core/sync/repositories/sync_repository.dart (Clase SyncRepositoryImpl)

import '../models/sync_models.dart';
import '../services/firebase_service.dart';
import '../services/sync_manager.dart';
import '../../auth/interfaces/i_auth_service.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

// La interfaz abstracta SyncRepository (sin cambios en esta sección específica)
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
  
  Future<void> deleteHabitRemotely(String userId, int habitId); 

  void pauseAutoSync();
  void resumeAutoSync();
}

// Implementación de SyncRepositoryImpl (sin lógica de temporizador)
class SyncRepositoryImpl implements SyncRepository {
  final SyncManager _syncManager; // Inyección de SyncManager
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
      appLog('🔄 [SyncRepo] Iniciando sincronización completa...');
      final result = await _syncManager.syncAll();
      appLog('✅ [SyncRepo] Sincronización completa: ${result ? "exitosa" : "fallida"}');
      return result;
    } catch (e) {
      appLog('❌ [SyncRepo] Error en syncAll: $e');
      return false;
    }
  }

  @override
  Future<bool> syncHabitsOnly() async {
    try {
      appLog('🔄 [SyncRepo] Iniciando sync solo de hábitos...');
      final result = await _syncManager.syncHabitsOnly();
      appLog('✅ [SyncRepo] Sync de hábitos: ${result ? "exitoso" : "fallido"}');
      return result;
    } catch (e) {
      appLog('❌ [SyncRepo] Error en syncHabitsOnly: $e');
      return false;
    }
  }

  @override
  Future<bool> syncEntriesOnly() async {
    try {
      appLog('🔄 [SyncRepo] Iniciando sync solo de entradas...');
      final result = await _syncManager.syncEntriesOnly();
      appLog('✅ [SyncRepo] Sync de entradas: ${result ? "exitoso" : "fallido"}');
      return result;
    } catch (e) {
      appLog('❌ [SyncRepo] Error en syncEntriesOnly: $e');
      return false;
    }
  }

  @override
  Future<void> requestSync() async {
    try {
      appLog('🔄 [SyncRepo] Sync solicitado manualmente...');
      await _syncManager.requestSync(); // Delega la solicitud a SyncManager
      appLog('✅ [SyncRepo] Sync manual completado');
    } catch (e) {
      appLog('❌ [SyncRepo] Error en requestSync: $e');
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      return await _firebaseService.hasInternetConnection();
    } catch (e) {
      appLog('❌ [SyncRepo] Error verificando conexión: $e');
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
      appLog('❌ [SyncRepo] Error obteniendo último sync remoto: $e');
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
      appLog('❌ [SyncRepo] Error verificando conflictos: $e');
      return false;
    }
  }

  @override
  Future<void> deleteHabitRemotely(String userId, int habitId) async {
    try {
      // Delega la eliminación física en Firestore al FirebaseService
      await _firebaseService.deleteHabitInFirestore(userId, habitId); 
      appLog('✅ [SyncRepo] Hábito $habitId eliminado remotamente en Firebase a través de SyncRepo.');
    } catch (e) {
      appLog('❌ [SyncRepo] Error eliminando hábito $habitId remotamente en SyncRepo: $e');
      rethrow; 
    }
  }

  @override
  void pauseAutoSync() {
    _syncManager.pauseAutoSync(); // Delega a SyncManager
    appLog('⏸️ [SyncRepo] Auto-sync pausado');
  }

  @override
  void resumeAutoSync() {
    _syncManager.resumeAutoSync(); // Delega a SyncManager
    appLog('▶️ [SyncRepo] Auto-sync reanudado');
  }
}
