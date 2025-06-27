import 'package:habitiurs/core/auth/exceptions/auth_exceptions.dart';

import '../interfaces/i_auth_service.dart';
import '../models/auth_result.dart';
import '../models/user.dart';
import '../mappers/user_mapper.dart';
import 'firebase_auth_provider.dart';
import 'google_auth_provider.dart';
import '../../common/interfaces/disposable.dart';

/// Main authentication service
class AuthService implements IAuthService, Disposable {
  final FirebaseAuthProvider _firebaseProvider;
  final GoogleAuthProvider _googleProvider;
  
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  AuthService._internal()
      : _firebaseProvider = FirebaseAuthProvider(),
        _googleProvider = GoogleAuthProvider();

  @override
  Stream<User?> get authStateChanges => _firebaseProvider.authStateChanges;

  @override
  User? get currentUser => _firebaseProvider.currentUser;

  @override
  Future<AuthResult<User>> signInWithGoogle() async {
    final googleResult = await _googleProvider.signInWithGoogle();
    
    return await googleResult.fold(
      (credential) => _firebaseProvider.signInWithCredential(credential),
      (error) => AuthResultExtensions.failure(error as AuthException),
    );
  }

  @override
  Future<AuthResult<void>> signOut() async {
    final futures = [
      _firebaseProvider.signOut(),
      _googleProvider.signOut(),
    ];
    
    final results = await Future.wait(futures);
    
    // Return success if any provider succeeds
    for (final result in results) {
      if (result.isSuccess) {
        return AuthResultExtensions.success(null);
      }
    }
    
    // If all failed, return the first error
    return results.first;
  }

  @override
  User createGuestUser() => UserMapper.createGuestUser();

  @override
  Future<bool> hasInternetConnection() async {
    return await _firebaseProvider.hasInternetConnection();
  }

  @override
  Future<void> dispose() async {
    await Future.wait([
      _firebaseProvider.dispose(),
      _googleProvider.dispose(),
    ]);
  }
}