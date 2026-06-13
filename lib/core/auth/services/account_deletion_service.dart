// lib/core/auth/services/account_deletion_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../di/injection_container.dart';
import '../models/auth_result.dart';
import '../exceptions/auth_exceptions.dart';
import 'auth_service.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

/// Orquesta la eliminación completa de la cuenta y todos sus datos:
/// 1. Datos remotos en Firestore (hábitos, entradas, documento de usuario)
/// 2. Cuenta de Firebase Auth (con re-autenticación si hace falta)
/// 3. Datos locales (sqflite + preferencias)
///
/// Para usuarios invitados solo se borran los datos locales.
class AccountDeletionService {
  Future<AuthResult<void>> deleteAccount() async {
    final container = InjectionContainer();
    final authService = AuthService();
    final user = authService.currentUser;
    final isGuest = user == null || user.isGuest;

    try {
      if (!isGuest) {
        // 1. Datos remotos primero (mientras todavía hay sesión válida)
        await container.firebaseService.deleteAllUserData(user.id);

        // 2. Cuenta de Firebase Auth
        final result = await authService.deleteCurrentUser();
        if (result is AuthFailure) {
          return result;
        }
      }

      // 3. Datos locales: base de datos y preferencias
      await container.databaseHelper.clearAllData();
      await authService.clearGuestSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      appLog('✅ [AccountDeletion] Cuenta y datos eliminados por completo');
      return const AuthSuccess(null);
    } catch (e) {
      appLog('❌ [AccountDeletion] Error: $e');
      return AuthFailure(
        UnknownAuthException('No se pudo eliminar la cuenta: $e'),
      );
    }
  }
}
