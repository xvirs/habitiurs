import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:habitiurs/core/auth/models/user_preferences.dart';
import '../interfaces/i_auth_service.dart';
import '../models/user.dart';
import '../models/auth_result.dart';
import '../exceptions/auth_exceptions.dart';

/// Implementación robusta del servicio de autenticación
class AuthService implements IAuthService {
  firebase.FirebaseAuth? _firebaseAuth;
  GoogleSignIn? _googleSignIn;
  bool _initialized = false;
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
        scopes: [
          'email',
          'profile',
        ],
        // ✅ IMPORTANTE: Configurar para desarrollo/debug
        signInOption: SignInOption.standard,
      );
      
      _initialized = true;
      print('✅ [AuthService] Servicios inicializados correctamente');
    } catch (e) {
      print('❌ [AuthService] Error inicializando servicios: $e');
      _initialized = false;
    }
  }

  @override
  Stream<User?> get authStateChanges {
    if (!_initialized || _firebaseAuth == null) {
      print('❌ [AuthService] authStateChanges: No inicializado o firebaseAuth es null. Retornando stream vacío.'); // DEBUG LOG
      return Stream.value(null);
    }
    
    try {
      print('🔄 [AuthService] authStateChanges: Escuchando cambios en Firebase Auth.'); // DEBUG LOG
      return _firebaseAuth!.authStateChanges().map((firebaseUser) {
        print('🔄 [AuthService] authStateChanges: Firebase User cambió a: ${firebaseUser?.email ?? 'null'}'); // DEBUG LOG
        return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
      });
    } catch (e) {
      print('❌ [AuthService] Error en authStateChanges: $e');
      return Stream.value(null);
    }
  }

  @override
  User? get currentUser {
    if (!_initialized || _firebaseAuth == null) {
      print('❌ [AuthService] currentUser: No inicializado o firebaseAuth es null. Retornando null.'); // DEBUG LOG
      return null;
    }
    
    try {
      final firebaseUser = _firebaseAuth!.currentUser;
      print('🔄 [AuthService] currentUser: Firebase User actual es: ${firebaseUser?.email ?? 'null'}'); // DEBUG LOG
      return firebaseUser != null ? _mapFirebaseUser(firebaseUser) : null;
    } catch (e) {
      print('❌ [AuthService] Error obteniendo usuario actual: $e');
      return null;
    }
  }

  @override
  Future<AuthResult<User>> signInWithGoogle() async {
    if (!_initialized) {
      return const AuthFailure(
        UnknownAuthException('Servicio de autenticación no inicializado')
      );
    }

    try {
      if (_googleSignIn == null) {
        return const AuthFailure(
          UnknownAuthException('Google Sign In no disponible')
        );
      }

      print('🔄 [AuthService] Iniciando Google Sign-In...');

      // ✅ MEJORADO: Limpiar sesión anterior si existe
      print('🔄 [AuthService] Intentando signOut previo de GoogleSignIn...'); // DEBUG LOG
      await _googleSignIn!.signOut();
      print('✅ [AuthService] signOut previo de GoogleSignIn completado.'); // DEBUG LOG
      
      // ✅ MEJORADO: Intentar sign in con manejo de errores más específico
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        print('⚠️ [AuthService] Usuario canceló el login');
        return const AuthFailure(LoginCancelledException());
      }

      print('✅ [AuthService] Usuario seleccionado: ${googleUser.email}');

      // ✅ MEJORADO: Obtener autenticación con retry
      GoogleSignInAuthentication googleAuth;
      try {
        print('🔄 [AuthService] Intentando obtener autenticación de Google...'); // DEBUG LOG
        googleAuth = await googleUser.authentication;
        print('✅ [AuthService] Autenticación de Google obtenida.'); // DEBUG LOG
      } catch (e) {
        print('❌ [AuthService] Error obteniendo authentication: $e. Reintentando...'); // DEBUG LOG
        // Intentar una segunda vez
        await Future.delayed(const Duration(seconds: 1));
        try {
          googleAuth = await googleUser.authentication;
          print('✅ [AuthService] Autenticación de Google obtenida en segundo intento.'); // DEBUG LOG
        } catch (e2) {
          print('❌ [AuthService] Error en segundo intento: $e2');
          return const AuthFailure(
            UnknownAuthException('No se pudo obtener autenticación de Google')
          );
        }
      }

      print('🔍 [AuthService] Tokens obtenidos - AccessToken: ${googleAuth.accessToken != null ? "SÍ" : "NO"}, IdToken: ${googleAuth.idToken != null ? "SÍ" : "NO"}');

      // ✅ MEJORADO: Verificación más detallada de tokens
      if (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty) {
        print('❌ [AuthService] AccessToken es null o vacío');
        return const AuthFailure(
          UnknownAuthException('No se pudo obtener Access Token de Google')
        );
      }

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        print('❌ [AuthService] IdToken es null o vacío');
        return const AuthFailure(
          UnknownAuthException('No se pudo obtener ID Token de Google')
        );
      }

      // Crear credencial de Firebase
      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (_firebaseAuth == null) {
        return const AuthFailure(
          UnknownAuthException('Firebase Auth no disponible')
        );
      }

      print('🔄 [AuthService] Autenticando con Firebase...');

      // ✅ MEJORADO: Sign in con Firebase con timeout
      final firebase.UserCredential result = await _firebaseAuth!
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));
      
      if (result.user != null) {
        final user = _mapFirebaseUser(result.user!);
        print('✅ [AuthService] Login exitoso para: ${user.email}');
        return AuthSuccess(user);
      }
      
      return const AuthFailure(
        UnknownAuthException('No se pudo obtener usuario después del login')
      );
      
    } on firebase.FirebaseAuthException catch (e) {
      print('❌ [AuthService] Firebase Auth Error: ${e.code} - ${e.message}');
      return AuthFailure(_mapFirebaseAuthException(e));
    } catch (e) {
      print('❌ [AuthService] Error inesperado en login: $e');
      return AuthFailure(UnknownAuthException('Error inesperado: $e'));
    }
  }

  @override
  Future<AuthResult<void>> signOut() async {
    if (!_initialized) {
      return const AuthFailure(
        UnknownAuthException('Servicio de autenticación no inicializado')
      );
    }

    try {
      final futures = <Future>[];
      
      if (_firebaseAuth != null) {
        print('### AuthService: Intentando signOut de Firebase.'); // DEBUG LOG
        futures.add(_firebaseAuth!.signOut());
      }
      
      if (_googleSignIn != null) {
        print('### AuthService: Intentando signOut de GoogleSignIn.'); // DEBUG LOG
        futures.add(_googleSignIn!.signOut());
      }
      
      await Future.wait(futures);
      print('✅ [AuthService] Logout exitoso');
      return const AuthSuccess(null);
    } catch (e) {
      print('❌ [AuthService] Error durante logout: $e');
      return AuthFailure(UnknownAuthException('Error durante logout: $e'));
    }
  }

  @override
  User createGuestUser() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final guestUser = User(
      id: 'guest_$timestamp',
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
    
    print('✅ [AuthService] Usuario invitado creado: ${guestUser.id}');
    return guestUser;
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      if (_firebaseAuth == null) return false;
      
      await _firebaseAuth!.currentUser?.reload();
      return true;
    } catch (e) {
      print('❌ [AuthService] Sin conexión: $e');
      return false;
    }
  }

  @override
  void dispose() {
    print('🧹 [AuthService] Limpiando recursos');
  }

  // ✅ MEJORADO: Método para debugging de Google Sign-In
  Future<void> debugGoogleSignIn() async {
    if (_googleSignIn == null) {
      print('❌ [Debug] GoogleSignIn es null');
      return;
    }

    try {
      print('🔍 [Debug] Verificando estado de GoogleSignIn...');
      
      final isSignedIn = await _googleSignIn!.isSignedIn();
      print('🔍 [Debug] Ya está signed in: $isSignedIn');
      
      if (isSignedIn) {
        final currentAccount = _googleSignIn!.currentUser;
        print('🔍 [Debug] Cuenta actual: ${currentAccount?.email}');
      }
      
      // Verificar si hay cuentas disponibles
      print('🔍 [Debug] Intentando obtener cuenta...');
      
    } catch (e) {
      print('❌ [Debug] Error en debug: $e');
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
      print('❌ [AuthService] Error mapeando usuario Firebase: $e');
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
        return const UnknownAuthException('Demasiados intentos. Espera un momento.');
      case 'user-disabled':
        return const UnknownAuthException('Esta cuenta ha sido deshabilitada');
      default:
        return UnknownAuthException('Error de Firebase: ${e.message ?? e.code}');
    }
  }
}
