// lib/core/auth/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  AuthService._internal()
      : _firebaseAuth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn();

  // Stream del estado de autenticación
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
    });
  }

  // Usuario actual
  AppUser? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
  }

  // Login con Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw AuthException('Login cancelado por el usuario');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _firebaseAuth.signInWithCredential(credential);
      
      if (result.user != null) {
        return _mapFirebaseUser(result.user!);
      }
      
      return null;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthException('Error durante el login: $e');
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Error durante el logout: $e');
    }
  }

  // Eliminar cuenta
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
        await _googleSignIn.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException('Necesitas volver a autenticarte para eliminar tu cuenta');
      }
      throw AuthException('Error al eliminar cuenta: ${e.message}');
    }
  }

  // Mapear Usuario de Firebase a AppUser
  AppUser _mapFirebaseUser(User firebaseUser) {
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoURL: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLogin: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      isPremium: false, // Se actualizará desde Firestore
      preferences: {}, // Se cargarán desde Firestore
    );
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este email usando otro método de login';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'user-not-found':
        return 'No se encontró un usuario con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'too-many-requests':
        return 'Demasiados intentos. Prueba más tarde';
      default:
        return 'Error de autenticación: $code';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

// lib/core/sync/models/sync_models.dart
enum SyncStatus {
  pending,
  syncing,
  completed,
  failed,
  conflict,
}

class SyncOperation {
  final String id;
  final String entityType; // 'habit', 'habit_entry', 'user_preferences'
  final String entityId;
  final SyncOperationType operation; // create, update, delete
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final SyncStatus status;
  final String? error;

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.data,
    required this.timestamp,
    this.status = SyncStatus.pending,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.toString(),
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString(),
      'error': error,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      operation: SyncOperationType.values.firstWhere(
        (e) => e.toString() == json['operation'],
      ),
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      status: SyncStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => SyncStatus.pending,
      ),
      error: json['error'],
    );
  }

  SyncOperation copyWith({
    SyncStatus? status,
    String? error,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      data: data,
      timestamp: timestamp,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

enum SyncOperationType {
  create,
  update,
  delete,
}
