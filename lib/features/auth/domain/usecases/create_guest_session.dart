// lib/features/auth/domain/usecases/create_guest_session.dart

import 'package:habitiurs/core/auth/interfaces/i_auth_service.dart';
import 'package:habitiurs/core/auth/models/user.dart';

class CreateGuestSession {
  final IAuthService _authService;

  const CreateGuestSession(this._authService);

  User call() {
    return _authService.createGuestUser();
  }
}
