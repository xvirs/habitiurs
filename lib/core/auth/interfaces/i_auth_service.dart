// lib/core/auth/interfaces/i_auth_service.dart
import '../models/user.dart';
import '../models/auth_result.dart';

/// Contrato principal del servicio de autenticación
abstract class IAuthService {
  /// Stream del estado de autenticación actual
  Stream<User?> get authStateChanges;
  
  /// Usuario actual (null si no está autenticado)
  User? get currentUser;
  
  /// Iniciar sesión con Google
  Future<AuthResult<User>> signInWithGoogle();
  
  /// Cerrar sesión
  Future<AuthResult<void>> signOut();
  
  /// Crear usuario invitado temporal
  User createGuestUser();
  
  /// Verificar si hay conexión para auth
  Future<bool> hasInternetConnection();
  
  /// Cleanup resources
  void dispose();
}
