// lib/core/sync/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habitiurs/core/auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';

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
  Future<void> createOrUpdateUser(AppUser user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw FirebaseException('Error guardando usuario: $e');
    }
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      
      return doc.exists ? AppUser.fromJson(doc.data()!) : null;
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

      // Limpiar hábitos existentes del usuario
      final existingHabits = await userHabitsRef.get();
      for (final doc in existingHabits.docs) {
        batch.delete(doc.reference);
      }

      // Agregar hábitos actuales
      for (final habit in habits) {
        final docRef = userHabitsRef.doc(habit['id'].toString());
        batch.set(docRef, {
          ...habit,
          'user_id': userId,
          'last_sync': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
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

      return snapshot.docs
          .map((doc) => {...doc.data(), 'firestore_id': doc.id})
          .toList();
    } catch (e) {
      throw FirebaseException('Error obteniendo hábitos: $e');
    }
  }

  // HABIT ENTRIES SYNC
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
          final docRef = userEntriesRef.doc('${entry['habit_id']}_${entry['date']}');
          batch.set(docRef, {
            ...entry,
            'user_id': userId,
            'last_sync': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        
        await batch.commit();
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
        query = query.where('last_sync', isGreaterThan: Timestamp.fromDate(since));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'firestore_id': doc.id})
          .toList();
    } catch (e) {
      throw FirebaseException('Error obteniendo entradas: $e');
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
}

class FirebaseException implements Exception {
  final String message;
  FirebaseException(this.message);
  @override
  String toString() => 'FirebaseException: $message';
}