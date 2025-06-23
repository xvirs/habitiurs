// lib/core/sync/services/firebase_service.dart - MODIFICADO (NOMBRE DE MÉTODO CORREGIDO)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habitiurs/core/auth/models/user_preferences.dart';
import '../../auth/models/user.dart';
import '../models/sync_models.dart';

class FirebaseService {
  final FirebaseFirestore _firestore;
  
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  
  FirebaseService._internal() : _firestore = FirebaseFirestore.instance;

  // COLECCIONES
  static const String _usersCollection = 'users';
  static const String _habitsCollection = 'habits';
  static const String _habitEntriesCollection = 'habit_entries';
  static const String _syncOperationsCollection = 'sync_operations';

  // USER OPERATIONS
  Future<void> createOrUpdateUser(User user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(_userToJson(user), SetOptions(merge: true));
    } catch (e) {
      throw FirebaseException('Error guardando usuario: $e');
    }
  }

  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      return doc.exists ? _userFromJson(doc.data()!) : null;
    } catch (e) {
      throw FirebaseException('Error obteniendo usuario: $e');
    }
  }

  // HABITS SYNC - CORREGIDO PARA MULTI-DISPOSITIVO
  Future<void> syncHabits(String userId, List<Map<String, dynamic>> habits) async {
    try {
      final batch = _firestore.batch();
      final userHabitsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitsCollection);

      // CAMBIO CRÍTICO: No limpiar hábitos existentes, solo hacer merge
      for (final habit in habits) {
        final habitId = habit['id'].toString();
        final docRef = userHabitsRef.doc(habitId);
        
        // Usar merge para no sobrescribir datos de otros dispositivos
        // Esto incluye el campo 'is_active'
        batch.set(docRef, {
          'id': habit['id'],
          'name': habit['name'],
          'created_at': habit['created_at'],
          'is_active': habit['is_active'], // Asegurarse de que is_active se guarda
          'user_id': userId,
          'last_sync': FieldValue.serverTimestamp(),
          'device_sync_time': DateTime.now().toIso8601String(), // Timestamp del dispositivo
        }, SetOptions(merge: true));
      }

      await batch.commit();
      print('✅ [Firebase] ${habits.length} hábitos sincronizados con merge');
    } catch (e) {
      throw FirebaseException('Error sincronizando hábitos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHabits(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitsCollection)
          // .where('is_active', isEqualTo: 1) // ELIMINAR ESTA LÍNEA si existía para obtener todos los hábitos
          .orderBy('created_at')
          .get();

      final habits = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'],
          'name': data['name'],
          'created_at': data['created_at'],
          'is_active': data['is_active'],
          'last_sync': data['last_sync'],
          'firestore_id': doc.id,
        };
      }).toList();

      print('☁️ [Firebase] Descargados ${habits.length} hábitos para usuario $userId');
      return habits;
    } catch (e) {
      throw FirebaseException('Error obteniendo hábitos: $e');
    }
  }

  // ✅ CORREGIDO: Renombrado de 'deleteHabitFromFirestore' a 'markHabitAsInactiveInFirestore'
  Future<void> markHabitAsInactiveInFirestore(String userId, int habitId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitsCollection)
          .doc(habitId.toString())
          .update({'is_active': 0, 'last_sync': FieldValue.serverTimestamp()}); // Marca como inactivo
      print('✅ [Firebase] Hábito marcado como inactivo en Firestore: $habitId');
    } catch (e) {
      throw FirebaseException('Error marcando hábito como inactivo en Firestore: $e');
    }
  }

  // HABIT ENTRIES SYNC - CORREGIDO PARA MULTI-DISPOSITIVO
  Future<void> syncHabitEntries(String userId, List<Map<String, dynamic>> entries) async {
    try {
      final batch = _firestore.batch();
      final userEntriesRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitEntriesCollection);

      // Sync por chunks para evitar límites de Firestore
      const chunkSize = 500;
      
      for (int i = 0; i < entries.length; i += chunkSize) {
        final chunk = entries.skip(i).take(chunkSize).toList();
        
        for (final entry in chunk) {
          // CLAVE ÚNICA: habitId_fecha para evitar duplicados
          final entryKey = '${entry['habit_id']}_${entry['date']}';
          final docRef = userEntriesRef.doc(entryKey);
          
          // Usar merge para preservar datos de otros dispositivos
          batch.set(docRef, {
            'habit_id': entry['habit_id'],
            'date': entry['date'],
            'status': entry['status'],
             if (entry['id'] != null) 'entry_id': entry['id'],
            'user_id': userId,
            'last_sync': FieldValue.serverTimestamp(),
            'device_sync_time': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
        
        await batch.commit();
        print('✅ [Firebase] Chunk ${(i / chunkSize).floor() + 1} sincronizado (${chunk.length} entradas)');
      }
    } catch (e) {
      throw FirebaseException('Error sincronizando entradas: $e');
    }
  }

  // MEJORADO: Descarga de entradas con filtro por fecha
  Future<List<Map<String, dynamic>>> getHabitEntries(String userId, {DateTime? since}) async {
    try {
      Query query = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitEntriesCollection);

      // CORRECCIÓN: Filtrar por fecha de la entrada, no por last_sync
      if (since != null) {
        final sinceString = since.toIso8601String().split('T')[0]; // Solo fecha
        query = query.where('date', isGreaterThanOrEqualTo: sinceString);
      }

      final snapshot = await query.get();
      
      final entries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'habit_id': data['habit_id'],
          'date': data['date'],
          'status': data['status'],
          'entry_id': data['entry_id'],
          'last_sync': data['last_sync'],
          'firestore_id': doc.id,
        };
      }).toList();

      print('☁️ [Firebase] Descargadas ${entries.length} entradas para usuario $userId (desde ${since?.toString().split(' ')[0] ?? 'inicio'})');
      return entries;
    } catch (e) {
      throw FirebaseException('Error obteniendo entradas: $e');
    }
  }

  // Método para obtener el último timestamp de sincronización
  Future<DateTime?> getLastSyncTimestamp(String userId, String collectionType) async {
    try {
      String collection = collectionType == 'habits' ? _habitsCollection : _habitEntriesCollection;
      
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(collection)
          .orderBy('last_sync', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final timestamp = snapshot.docs.first.data()['last_sync'] as Timestamp?;
        return timestamp?.toDate();
      }
      
      return null;
    } catch (e) {
      print('⚠️ [Firebase] Error obteniendo último timestamp: $e');
      return null;
    }
  }

  // Verificar si hay conflictos de datos
  Future<bool> hasConflicts(String userId, String collectionType, DateTime localLastSync) async {
    try {
      final remoteLastSync = await getLastSyncTimestamp(userId, collectionType);
      
      if (remoteLastSync == null) return false;
      
      // Hay conflicto si el timestamp remoto es más nuevo que el local
      return remoteLastSync.isAfter(localLastSync);
    } catch (e) {
      print('⚠️ [Firebase] Error verificando conflictos: $e');
      return false;
    }
  }

  // SYNC OPERATIONS
  Future<void> logSyncOperation(SyncOperation operation) async {
    try {
      await _firestore
          .collection(_syncOperationsCollection)
          .doc(operation.id)
          .set(operation.toJson());
    } catch (e) {
      print('⚠️ Error logging sync operation: $e');
      // No lanzar excepción para no interrumpir el flujo principal
    }
  }

  // UTILITIES
  Future<DateTime> getServerTimestamp() async {
    try {
      final doc = await _firestore.collection('_timestamp').add({
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      final snapshot = await doc.get();
      await doc.delete(); // Limpiar
      
      final timestamp = snapshot.data()?['timestamp'] as Timestamp?;
      return timestamp?.toDate() ?? DateTime.now();
    } catch (e) {
      return DateTime.now(); // Fallback
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      await _firestore.enableNetwork();
      return true;
    } catch (e) {
      return false;
    }
  }

  // PRIVATE HELPERS para convertir User ↔ JSON
  Map<String, dynamic> _userToJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoURL,
      'created_at': user.createdAt.toIso8601String(),
      'last_login': user.lastLogin.toIso8601String(),
      'is_premium': user.isPremium,
      'preferences': {
        'mode': user.preferences.mode.name,
        'settings': user.preferences.settings,
      },
    };
  }

  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'],
      photoURL: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: DateTime.parse(json['last_login']),
      isPremium: json['is_premium'] ?? false,
      preferences: UserPreferences(
        mode: UserMode.values.byName(json['preferences']?['mode'] ?? 'authenticated'),
        settings: Map<String, dynamic>.from(json['preferences']?['settings'] ?? {}),
      ),
    );
  }
}

class FirebaseException implements Exception {
  final String message;
  FirebaseException(this.message);
  @override
  String toString() => 'FirebaseException: $message';
}