import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:habitiurs/core/auth/models/user_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/i_auth_service.dart';
import '../models/user.dart';
import '../models/auth_result.dart';
import '../exceptions/auth_exceptions.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

/// Implementación robusta del servicio de autenticación
class AuthService implements IAuthService {
  firebase.FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;
  bool _initialized = false;
  String? _persistedGuestId;
  static const _guestIdKey = 'habitiurs_guest_id';
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _initializeServices();
  }

  void _initializeServices() {
    try {
      _firebaseAuth = firebase.FirebaseAuth.instance;

      // ✅ CORREGIDO: Configuración más específica de GoogleSignIn
      _googleSignIn = GoogleSignIn(
        // Estos scopes son los mínimos necesarios
        scopes: ['email', 'profile'],
        // ✅ IMPORTANTE: Configurar para desarrollo/debug
        signInOption: SignInOption.standard,
      );

      _initialized = true;
      appLog('✅ [AuthService] Servicios inicializados correctamente');
    } catch (e) {
      appLog('❌ [AuthService] Error inicializando servicios: $e');
      _initialized = false;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    if (!_initialized || _firebaseAuth == null) {
      appLog(
        '❌ [AuthService] authStateChanges: No inicializado o firebaseAuth es null. Retornando stream vacío.',
      ); // DEBUG LOG
      return Stream.value(null);
    }

    try {
      appLog(
        '🔄 [AuthService] authStateChanges: Escuchando cambios en Firebase Auth.',
      ); // DEBUG LOG
      return _firebaseAuth!.authStateChanges().map((firebaseUser) {
        appLog(
          '🔄 [AuthService] authStateChanges: Firebase User cambió a: ${firebaseUser?.email ?? 'null'}',
        ); // DEBUG LOG
        return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
      });
    } catch (e) {
      appLog('❌ [AuthService] Error en authStateChanges: $e');
      return Stream.value(null);
    }
  }

  @override
  User? get currentUser {
    if (!_initialized || _firebaseAuth == null) {
      appLog(
        '❌ [AuthService] currentUser: No inicializado o firebaseAuth es null. Retornando null.',
      ); // DEBUG LOG
      return null;
    }

    try {
      final firebaseUser = _firebaseAuth!.currentUser;
      appLog(
        '🔄 [AuthService] currentUser: Firebase User actual es: ${firebaseUser?.email ?? 'null'}',
      ); // DEBUG LOG
      return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
    } catch (e) {
      appLog('❌ [AuthService] Error obteniendo usuario actual: $e');
      return null;
    }
  }

  @override
  Future<AuthResult<User>> signInWithGoogle() async {
    if (!_initialized) {
      return const AuthFailure(
        UnknownAuthException('Servicio de autenticación no inicializado'),
      );
    }

    try {
      if (_googleSignIn == null) {
        return const AuthFailure(
          UnknownAuthException('Google Sign In no disponible'),
        );
      }

      appLog('🔄 [AuthService] Iniciando Google Sign-In...');

      // ✅ MEJORADO: Limpiar sesión anterior si existe
      appLog(
        '🔄 [AuthService] Intentando signOut previo de GoogleSignIn...',
      ); // DEBUG LOG
      await _googleSignIn!.signOut();
      appLog(
        '✅ [AuthService] signOut previo de GoogleSignIn completado.',
      ); // DEBUG LOG

      // ✅ MEJORADO: Intentar sign in con manejo de errores más específico
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        appLog('⚠️ [AuthService] Usuario canceló el login');
        return const AuthFailure(LoginCancelledException());
      }

      appLog('✅ [AuthService] Usuario seleccionado: ${googleUser.email}');

      // ✅ MEJORADO: Obtener autenticación con retry
      GoogleSignInAuthentication googleAuth;
      try {
        appLog(
          '🔄 [AuthService] Intentando obtener autenticación de Google...',
        ); // DEBUG LOG
        googleAuth = await googleUser.authentication;
        appLog(
          '✅ [AuthService] Autenticación de Google obtenida.',
        ); // DEBUG LOG
      } catch (e) {
        appLog(
          '❌ [AuthService] Error obteniendo authentication: $e. Reintentando...',
        ); // DEBUG LOG
        // Intentar una segunda vez
        await Future.delayed(const Duration(seconds: 1));
        try {
          googleAuth = await googleUser.authentication;
          appLog(
            '✅ [AuthService] Autenticación de Google obtenida en segundo intento.',
          ); // DEBUG LOG
        } catch (e2) {
          appLog('❌ [AuthService] Error en segundo intento: $e2');
          return const AuthFailure(
            UnknownAuthException('No se pudo obtener autenticación de Google'),
          );
        }
      }

      appLog(
        '🔍 [AuthService] Tokens obtenidos - AccessToken: ${googleAuth.accessToken != null ? "SÍ" : "NO"}, IdToken: ${googleAuth.idToken != null ? "SÍ" : "NO"}',
      );

      // ✅ MEJORADO: Verificación más detallada de tokens
      if (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty) {
        appLog('❌ [AuthService] AccessToken es null o vacío');
        return const AuthFailure(
          UnknownAuthException('No se pudo obtener Access Token de Google'),
        );
      }

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        appLog('❌ [AuthService] IdToken es null o vacío');
        return const AuthFailure(
          UnknownAuthException('No se pudo obtener ID Token de Google'),
        );
      }

      // Crear credencial de Firebase
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_firebaseAuth == null) {
        return const AuthFailure(
          UnknownAuthException('Firebase Auth no disponible'),
        );
      }

      appLog('🔄 [AuthService] Autenticando con Firebase...');

      // ✅ MEJORADO: Sign in con Firebase con timeout
      final firebase.UserCredential result = await _firebaseAuth!
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));

      if (result.user != null) {
        final user = _mapFirebaseUser(result.user!);
        appLog('✅ [AuthService] Login exitoso para: ${user.email}');
        return AuthSuccess(user);
      }

      return const AuthFailure(
        UnknownAuthException('No se pudo obtener usuario después del login'),
      );
    } on firebase.FirebaseAuthException catch (e) {
      appLog('❌ [AuthService] Firebase Auth Error: ${e.code} - ${e.message}');
      return AuthFailure(_mapFirebaseAuthException(e));
    } catch (e) {
      appLog('❌ [AuthService] Error inesperado en login: $e');
      return AuthFailure(UnknownAuthException('Error inesperado: $e'));
    }
  }

  @override
  Future<AuthResult<User>> signInWithApple() async {
    if (!_initialized || _firebaseAuth == null) {
      return const AuthFailure(
        UnknownAuthException('Servicio de autenticación no inicializado'),
      );
    }

    try {
      appLog('🔄 [AuthService] Iniciando Sign in with Apple...');

      // Apple requiere un nonce: enviamos el hash y luego el valor crudo a Firebase.
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthFailure(
          UnknownAuthException('No se pudo obtener el token de Apple'),
        );
      }

      final oauthCredential = firebase.OAuthProvider(
        'apple.com',
      ).credential(idToken: idToken, rawNonce: rawNonce);

      final result = await _firebaseAuth!
          .signInWithCredential(oauthCredential)
          .timeout(const Duration(seconds: 30));

      if (result.user == null) {
        return const AuthFailure(
          UnknownAuthException('No se pudo obtener usuario tras el login'),
        );
      }

      // Apple solo entrega el nombre en el PRIMER inicio de sesión. Si llega,
      // lo guardamos en el perfil de Firebase.
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      if ((result.user!.displayName == null ||
              result.user!.displayName!.isEmpty) &&
          (givenName != null || familyName != null)) {
        final fullName = [
          givenName,
          familyName,
        ].where((p) => p != null && p.isNotEmpty).join(' ');
        if (fullName.isNotEmpty) {
          await result.user!.updateDisplayName(fullName);
          await result.user!.reload();
        }
      }

      final user = _mapFirebaseUser(_firebaseAuth!.currentUser ?? result.user!);
      appLog('✅ [AuthService] Login con Apple exitoso para: ${user.email}');
      return AuthSuccess(user);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        appLog('⚠️ [AuthService] Login con Apple cancelado');
        return const AuthFailure(LoginCancelledException());
      }
      appLog('❌ [AuthService] Error de autorización Apple: ${e.code}');
      return AuthFailure(UnknownAuthException('Error de Apple: ${e.message}'));
    } on firebase.FirebaseAuthException catch (e) {
      appLog('❌ [AuthService] Firebase Auth Error (Apple): ${e.code}');
      return AuthFailure(_mapFirebaseAuthException(e));
    } catch (e) {
      appLog('❌ [AuthService] Error inesperado en login con Apple: $e');
      return AuthFailure(UnknownAuthException('Error inesperado: $e'));
    }
  }

  /// Genera un nonce criptográficamente seguro para Sign in with Apple.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  @override
  Future<AuthResult<void>> signOut() async {
    if (!_initialized) {
      return const AuthFailure(
        UnknownAuthException('Servicio de autenticación no inicializado'),
      );
    }

    try {
      final futures = <Future>[];

      if (_firebaseAuth != null) {
        appLog('### AuthService: Intentando signOut de Firebase.'); // DEBUG LOG
        futures.add(_firebaseAuth!.signOut());
      }

      if (_googleSignIn != null) {
        appLog(
          '### AuthService: Intentando signOut de GoogleSignIn.',
        ); // DEBUG LOG
        futures.add(_googleSignIn!.signOut());
      }

      await Future.wait(futures);
      appLog('✅ [AuthService] Logout exitoso');
      return const AuthSuccess(null);
    } catch (e) {
      appLog('❌ [AuthService] Error durante logout: $e');
      return AuthFailure(UnknownAuthException('Error durante logout: $e'));
    }
  }

  /// Elimina la cuenta de Firebase Auth del usuario actual.
  /// Si Firebase exige login reciente, re-autentica con Google y reintenta.
  Future<AuthResult<void>> deleteCurrentUser() async {
    final firebaseUser = _firebaseAuth?.currentUser;
    if (firebaseUser == null) {
      return const AuthFailure(
        UnknownAuthException('No hay usuario autenticado para eliminar'),
      );
    }

    try {
      try {
        await firebaseUser.delete();
      } on firebase.FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;

        appLog('🔄 [AuthService] Se requiere re-autenticación para eliminar.');
        final googleUser =
            await _googleSignIn?.signInSilently() ??
            await _googleSignIn?.signIn();
        if (googleUser == null) {
          return const AuthFailure(LoginCancelledException());
        }
        final googleAuth = await googleUser.authentication;
        final credential = firebase.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await firebaseUser.reauthenticateWithCredential(credential);
        await firebaseUser.delete();
      }

      await _googleSignIn?.signOut();
      appLog('🗑️ [AuthService] Cuenta de Firebase Auth eliminada');
      return const AuthSuccess(null);
    } on firebase.FirebaseAuthException catch (e) {
      appLog('❌ [AuthService] Error eliminando cuenta: ${e.code}');
      return AuthFailure(_mapFirebaseAuthException(e));
    } catch (e) {
      appLog('❌ [AuthService] Error inesperado eliminando cuenta: $e');
      return AuthFailure(UnknownAuthException('Error eliminando cuenta: $e'));
    }
  }

  /// Borra el ID de invitado persistido (al eliminar los datos locales).
  Future<void> clearGuestSession() async {
    _persistedGuestId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestIdKey);
  }

  @override
  User createGuestUser() {
    final String guestId;
    if (_persistedGuestId != null) {
      guestId = _persistedGuestId!;
      appLog('✅ [AuthService] Reutilizando guest ID existente: $guestId');
    } else {
      guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      _persistedGuestId = guestId;
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_guestIdKey, guestId),
      );
      appLog('✅ [AuthService] Nuevo guest ID creado y persistido: $guestId');
    }
    return User(
      id: guestId,
      email: 'guest@habitiurs.local',
      displayName: 'Usuario invitado',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isPremium: false,
      preferences: const UserPreferences(
        mode: UserMode.guest,
        settings: {'created_as_guest': true},
      ),
    );
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      if (_firebaseAuth == null) return false;
      final currentUser = _firebaseAuth!.currentUser;
      if (currentUser != null) {
        // Usuario autenticado: reload verifica conectividad con Firebase
        await currentUser.reload();
        return true;
      }
      // Modo invitado: DNS lookup para verificar conectividad real
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      appLog('❌ [AuthService] Sin conexión: $e');
      return false;
    }
  }

  @override
  Future<void> initGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    _persistedGuestId = prefs.getString(_guestIdKey);
    appLog(
      '🔄 [AuthService] Guest ID cargado: ${_persistedGuestId ?? "ninguno, se creará al primer uso"}',
    );
  }

  @override
  void dispose() {
    appLog('🧹 [AuthService] Limpiando recursos');
  }

  // ✅ MEJORADO: Método para debugging de Google Sign-In
  Future<void> debugGoogleSignIn() async {
    if (_googleSignIn == null) {
      appLog('❌ [Debug] GoogleSignIn es null');
      return;
    }

    try {
      appLog('🔍 [Debug] Verificando estado de GoogleSignIn...');

      final isSignedIn = await _googleSignIn!.isSignedIn();
      appLog('🔍 [Debug] Ya está signed in: $isSignedIn');

      if (isSignedIn) {
        final currentAccount = _googleSignIn!.currentUser;
        appLog('🔍 [Debug] Cuenta actual: ${currentAccount?.email}');
      }

      // Verificar si hay cuentas disponibles
      appLog('🔍 [Debug] Intentando obtener cuenta...');
    } catch (e) {
      appLog('❌ [Debug] Error en debug: $e');
    }
  }

  // Private helpers
  User _mapFirebaseUser(firebase.User firebaseUser) {
    try {
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLogin: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
        isPremium: false,
        preferences: const UserPreferences(mode: UserMode.authenticated),
      );
    } catch (e) {
      appLog('❌ [AuthService] Error mapeando usuario Firebase: $e');
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? 'unknown@email.com',
        displayName: firebaseUser.displayName ?? 'Usuario',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        preferences: const UserPreferences(mode: UserMode.authenticated),
      );
    }
  }

  AuthException _mapFirebaseAuthException(firebase.FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return const InvalidCredentialsException();
      case 'invalid-credential':
        return const InvalidCredentialsException();
      case 'user-not-found':
        return const InvalidCredentialsException();
      case 'wrong-password':
        return const InvalidCredentialsException();
      case 'network-request-failed':
        return const NetworkAuthException();
      case 'too-many-requests':
        return const UnknownAuthException(
          'Demasiados intentos. Espera un momento.',
        );
      case 'user-disabled':
        return const UnknownAuthException('Esta cuenta ha sido deshabilitada');
      default:
        return UnknownAuthException(
          'Error de Firebase: ${e.message ?? e.code}',
        );
    }
  }
}
