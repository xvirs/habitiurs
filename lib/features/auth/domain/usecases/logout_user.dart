// lib/features/auth/domain/usecases/logout_user.dart

import 'package:habitiurs/core/auth/interfaces/i_auth_service.dart';
import 'package:habitiurs/core/auth/models/auth_result.dart';

class LogoutUser {
  final IAuthService _authService;
  
  const LogoutUser(this._authService);
  
  Future<AuthResult<void>> call() async {
    return await _authService.signOut();
  }
}