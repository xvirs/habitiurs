import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../exceptions/auth_exceptions.dart';
import '../mappers/user_mapper.dart';
import '../models/auth_result.dart';
import '../models/user.dart';
import '../../common/interfaces/disposable.dart';

/// Firebase authentication provider
class FirebaseAuthProvider with DisposableMixin {
  firebase.FirebaseAuth? _firebaseAuth;
  bool _initialized = false;
  
  FirebaseAuthProvider() {
    _initialize();
  }

  void _initialize() {
    try {
      _firebaseAuth = firebase.FirebaseAuth.instance;
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges {
    if (!_initialized || _firebaseAuth == null) {
      return Stream.value(null);
    }
    
    return _firebaseAuth!.authStateChanges().map((firebaseUser) =>
        firebaseUser != null ? UserMapper.fromFirebaseUser(firebaseUser) : null);
  }

  /// Current authenticated user
  User? get currentUser {
    if (!_initialized || _firebaseAuth == null) return null;
    
    final firebaseUser = _firebaseAuth!.currentUser;
    return firebaseUser != null ? UserMapper.fromFirebaseUser(firebaseUser) : null;
  }

  /// Sign in with credential
  Future<AuthResult<User>> signInWithCredential(firebase.AuthCredential credential) async {
    ensureNotDisposed();
    
    if (!_initialized || _firebaseAuth == null) {
      return AuthResultExtensions.failure(
        const ServiceUnavailableException('Firebase Auth')
      );
    }

    try {
      final result = await _firebaseAuth!
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));
      
      if (result.user != null) {
        final user = UserMapper.fromFirebaseUser(result.user!);
        return AuthResultExtensions.success(user);
      }
      
      return AuthResultExtensions.failure(
        const UnknownAuthException('No user returned after sign in')
      );
    } on firebase.FirebaseAuthException catch (e) {
      return AuthResultExtensions.failure(_mapFirebaseException(e));
    } catch (e) {
      return AuthResultExtensions.failure(UnknownAuthException('Unexpected error: $e'));
    }
  }

  /// Sign out
  Future<AuthResult<void>> signOut() async {
    ensureNotDisposed();
    
    if (!_initialized || _firebaseAuth == null) {
      return AuthResultExtensions.failure(
        const ServiceUnavailableException('Firebase Auth')
      );
    }

    try {
      await _firebaseAuth!.signOut();
      return AuthResultExtensions.success(null);
    } catch (e) {
      return AuthResultExtensions.failure(UnknownAuthException('Sign out error: $e'));
    }
  }

  /// Check if service is available
  bool get isAvailable => _initialized && _firebaseAuth != null;

  /// Check internet connection through Firebase
  Future<bool> hasInternetConnection() async {
    try {
      if (!isAvailable) return false;
      await _firebaseAuth!.currentUser?.reload();
      return true;
    } catch (e) {
      return false;
    }
  }

  AuthException _mapFirebaseException(firebase.FirebaseAuthException e) {
    return switch (e.code) {
      'account-exists-with-different-credential' => const InvalidCredentialsException(),
      'invalid-credential' => const InvalidCredentialsException(),
      'user-not-found' => const InvalidCredentialsException(),
      'wrong-password' => const InvalidCredentialsException(),
      'network-request-failed' => const NetworkAuthException(),
      'too-many-requests' => const TooManyRequestsException(),
      'user-disabled' => const UserDisabledException(),
      _ => UnknownAuthException('Firebase error: ${e.message ?? e.code}'),
    };
  }

  @override
  Future<void> onDispose() async {
    // Firebase Auth doesn't need explicit disposal
  }
}