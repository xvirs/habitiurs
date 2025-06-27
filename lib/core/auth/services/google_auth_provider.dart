import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import '../exceptions/auth_exceptions.dart';
import '../models/auth_result.dart';
import '../../common/interfaces/disposable.dart';

class GoogleAuthProvider with DisposableMixin {
  GoogleSignIn? _googleSignIn;
  bool _initialized = false;
  
  GoogleAuthProvider() {
    _initialize();
  }

  void _initialize() {
    try {
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        signInOption: SignInOption.standard,
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
    }
  }

  Future<AuthResult<firebase.AuthCredential>> signInWithGoogle() async {
    ensureNotDisposed();
    
    if (!_initialized || _googleSignIn == null) {
      return AuthResultExtensions.failure(
        const ServiceUnavailableException('Google Sign In')
      );
    }

    try {
      await _googleSignIn!.signOut();
      
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      
      if (googleUser == null) {
        return AuthResultExtensions.failure(const LoginCancelledException());
      }

      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        await Future.delayed(const Duration(seconds: 1));
        try {
          googleAuth = await googleUser.authentication;
        } catch (e2) {
          return AuthResultExtensions.failure(
            const UnknownAuthException('Failed to get Google authentication')
          );
        }
      }

      if (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty) {
        return AuthResultExtensions.failure(
          const UnknownAuthException('Failed to get Google Access Token')
        );
      }

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        return AuthResultExtensions.failure(
          const UnknownAuthException('Failed to get Google ID Token')
        );
      }

      final credential = firebase.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return AuthResultExtensions.success(credential);
      
    } catch (e) {
      return AuthResultExtensions.failure(UnknownAuthException('Google sign in error: $e'));
    }
  }

  Future<AuthResult<void>> signOut() async {
    ensureNotDisposed();
    
    if (!_initialized || _googleSignIn == null) {
      return AuthResultExtensions.failure(
        const ServiceUnavailableException('Google Sign In')
      );
    }

    try {
      await _googleSignIn!.signOut();
      return AuthResultExtensions.success(null);
    } catch (e) {
      return AuthResultExtensions.failure(UnknownAuthException('Google sign out error: $e'));
    }
  }

  bool get isAvailable => _initialized && _googleSignIn != null;

  @override
  Future<void> onDispose() async {
    // Google Sign In doesn't need explicit disposal
  }
}