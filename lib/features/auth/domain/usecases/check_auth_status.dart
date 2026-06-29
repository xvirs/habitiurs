// lib/features/auth/domain/usecases/check_auth_status.dart

import 'package:habitiurs/core/auth/interfaces/i_auth_service.dart';
import 'package:habitiurs/core/auth/models/user.dart';

class CheckAuthStatus {
  final IAuthService _authService;

  const CheckAuthStatus(this._authService);

  Stream<User?> call() {
    return _authService.authStateChanges;
  }

  User? getCurrentUser() {
    return _authService.currentUser;
  }
}
