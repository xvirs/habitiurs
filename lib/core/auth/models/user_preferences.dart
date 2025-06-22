// lib/core/auth/models/user_preferences.dart
enum UserMode { authenticated, guest }

class UserPreferences {
  final UserMode mode;
  final Map<String, dynamic> settings;

  const UserPreferences({
    this.mode = UserMode.authenticated,
    this.settings = const {},
  });

  UserPreferences copyWith({
    UserMode? mode,
    Map<String, dynamic>? settings,
  }) {
    return UserPreferences(
      mode: mode ?? this.mode,
      settings: settings ?? this.settings,
    );
  }
}