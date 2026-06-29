// lib/features/auth/domain/usecases/login_with_google.dart

import 'package:habitiurs/core/auth/interfaces/i_auth_service.dart';
import 'package:habitiurs/core/auth/models/auth_result.dart';
import 'package:habitiurs/core/auth/models/user.dart';

class LoginWithGoogle {
  final IAuthService _authService;

  const LoginWithGoogle(this._authService);

  Future<AuthResult<User>> call() async {
    return await _authService.signInWithGoogle();
  }
}
