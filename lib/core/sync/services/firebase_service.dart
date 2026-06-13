// lib/core/sync/services/firebase_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habitiurs/core/auth/models/user_preferences.dart';
import '../../auth/models/user.dart';
import '../models/sync_models.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

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

  // HABITS SYNC 
  Future<void> syncHabits(String userId, List<Map<String, dynamic>> habits) async {
    try {
      final batch = _firestore.batch();
      final userHabitsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitsCollection);

      for (final habit in habits) {
        final habitId = habit['id'].toString();
        final docRef = userHabitsRef.doc(habitId);
        
        batch.set(docRef, {
          'id': habit['id'],
          'name': habit['name'],
          'created_at': habit['created_at'],
          'is_active': habit['is_active'],
          'color': habit['color'],
          'icon': habit['icon'],
          'weekdays': habit['weekdays'],
          'reminder_time': habit['reminder_time'],
          'user_id': userId,
          'last_sync': FieldValue.serverTimestamp(),
          'device_sync_time': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      appLog('✅ [Firebase] ${habits.length} hábitos sincronizados con merge');
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
          .orderBy('created_at')
          .get();

      final habits = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'],
          'name': data['name'],
          'created_at': data['created_at'],
          'is_active': data['is_active'],
          'color': data['color'],
          'icon': data['icon'],
          'weekdays': data['weekdays'],
          'reminder_time': data['reminder_time'],
          'last_sync': data['last_sync'],
          'firestore_id': doc.id,
        };
      }).toList();

      appLog('☁️ [Firebase] Descargados ${habits.length} hábitos para usuario $userId');
      return habits;
    } catch (e) {
      throw FirebaseException('Error obteniendo hábitos: $e');
    }
  }

  /// Borra TODOS los datos del usuario en Firestore: hábitos, entradas y
  /// el documento del usuario. Usado por el flujo de eliminación de cuenta.
  Future<void> deleteAllUserData(String userId) async {
    try {
      final userRef = _firestore.collection(_usersCollection).doc(userId);

      for (final collection in [_habitsCollection, _habitEntriesCollection]) {
        // Borrado por lotes (límite de 500 operaciones por batch)
        while (true) {
          final snapshot =
              await userRef.collection(collection).limit(400).get();
          if (snapshot.docs.isEmpty) break;
          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      }

      await userRef.delete();
      appLog('🗑️ [Firebase] Datos del usuario $userId eliminados de Firestore');
    } catch (e) {
      throw FirebaseException('Error eliminando datos del usuario: $e');
    }
  }

  Future<void> markHabitAsInactiveInFirestore(String userId, int habitId) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitsCollection)
          .doc(habitId.toString())
          .update({'is_active': 0, 'last_sync': FieldValue.serverTimestamp()});
      appLog('✅ [Firebase] Hábito marcado como inactivo en Firestore: $habitId');
    } catch (e) {
      throw FirebaseException('Error marcando hábito como inactivo en Firestore: $e');
    }
  }

  // NUEVO: Método para eliminar físicamente un hábito y sus entradas relacionadas en Firestore
  Future<void> deleteHabitInFirestore(String userId, int habitId) async {
    try {
      final userHabitsRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitsCollection);
      
      final userEntriesRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitEntriesCollection);

      final batch = _firestore.batch();

      // 1. Eliminar todas las entradas de hábito relacionadas
      final entriesToDeleteSnapshot = await userEntriesRef
          .where('habit_id', isEqualTo: habitId)
          .get();
      
      for (final doc in entriesToDeleteSnapshot.docs) {
        batch.delete(doc.reference);
      }
      appLog('DEBUG: Preparadas ${entriesToDeleteSnapshot.docs.length} entradas para eliminación en Firebase.');

      // 2. Eliminar el documento del hábito principal
      final habitDocRef = userHabitsRef.doc(habitId.toString());
      batch.delete(habitDocRef);
      appLog('DEBUG: Hábito $habitId preparado para eliminación en Firebase.');

      // 3. Ejecutar el batch
      await batch.commit();
      appLog('✅ [Firebase] Hábito $habitId y sus entradas relacionadas eliminados físicamente de Firestore.');
    } catch (e) {
      throw FirebaseException('Error eliminando hábito $habitId y sus entradas en Firestore: $e');
    }
  }

  // HABIT ENTRIES SYNC 
  Future<void> syncHabitEntries(String userId, List<Map<String, dynamic>> entries) async {
    try {
      final userEntriesRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitEntriesCollection);

      const chunkSize = 500;

      for (int i = 0; i < entries.length; i += chunkSize) {
        final chunk = entries.skip(i).take(chunkSize).toList();
        // Nuevo batch por chunk — un WriteBatch no puede reutilizarse tras commit()
        final chunkBatch = _firestore.batch();

        for (final entry in chunk) {
          final entryKey = '${entry['habit_id']}_${entry['date']}';
          final docRef = userEntriesRef.doc(entryKey);

          chunkBatch.set(docRef, {
            'habit_id': entry['habit_id'],
            'date': entry['date'],
            'status': entry['status'],
            if (entry['id'] != null) 'entry_id': entry['id'],
            'user_id': userId,
            'last_sync': FieldValue.serverTimestamp(),
            'device_sync_time': DateTime.now().toIso8601String(),
            // Preservar el timestamp real del cambio; solo usar server timestamp para entradas nuevas
            if (entry['last_modified'] != null)
              'last_modified': Timestamp.fromDate(DateTime.parse(entry['last_modified'] as String))
            else
              'last_modified': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        await chunkBatch.commit();
        appLog('✅ [Firebase] Chunk ${(i / chunkSize).floor() + 1} sincronizado (${chunk.length} entradas)');
      }
    } catch (e) {
      throw FirebaseException('Error sincronizando entradas: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHabitEntries(String userId, {DateTime? since}) async {
    try {
      Query query = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_habitEntriesCollection);

      if (since != null) {
        final sinceString = since.toIso8601String().split('T')[0]; 
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
          'last_modified': data['last_modified'] is Timestamp
              ? (data['last_modified'] as Timestamp).toDate().toIso8601String()
              : data['last_modified'] as String?,
        };
      }).toList();

      appLog('☁️ [Firebase] Descargadas ${entries.length} entradas para usuario $userId (desde ${since?.toString().split(' ')[0] ?? 'inicio'})');
      return entries;
    } catch (e) {
      throw FirebaseException('Error obteniendo entradas: $e');
    }
  }

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
      appLog('⚠️ [Firebase] Error obteniendo último timestamp: $e');
      return null;
    }
  }

  Future<bool> hasConflicts(String userId, String collectionType, DateTime localLastSync) async {
    try {
      final remoteLastSync = await getLastSyncTimestamp(userId, collectionType);
      
      if (remoteLastSync == null) return false;
      
      return remoteLastSync.isAfter(localLastSync);
    } catch (e) {
      appLog('⚠️ [Firebase] Error verificando conflictos: $e');
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
      appLog('⚠️ Error logging sync operation: $e');
    }
  }

  Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
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
