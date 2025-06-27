import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../models/user.dart';
import '../models/user_preferences.dart';

/// Mapper for User entities
class UserMapper {
  /// Map Firebase user to domain user
  static User fromFirebaseUser(firebase.User firebaseUser) {
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
      // Fallback for corrupted Firebase user data
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? 'unknown@email.com',
        displayName: firebaseUser.displayName ?? 'User',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        preferences: const UserPreferences(mode: UserMode.authenticated),
      );
    }
  }

  /// Create guest user with unique ID
  static User createGuestUser() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return User(
      id: 'guest_$timestamp',
      email: 'guest@habitiurs.local',
      displayName: 'Guest User',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isPremium: false,
      preferences: const UserPreferences(
        mode: UserMode.guest,
        settings: {'created_as_guest': true},
      ),
    );
  }

  /// Convert user to JSON for storage/sync
  static Map<String, dynamic> toJson(User user) => {
    'id': user.id,
    'email': user.email,
    'display_name': user.displayName,
    'photo_url': user.photoURL,
    'created_at': user.createdAt.toIso8601String(),
    'last_login': user.lastLogin.toIso8601String(),
    'is_premium': user.isPremium,
    'preferences': {
      'mode': user.preferences.mode.name,
      'settings': user.preferences.settings,
    },
  };

  /// Create user from JSON
  static User fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['display_name'] as String?,
    photoURL: json['photo_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    lastLogin: DateTime.parse(json['last_login'] as String),
    isPremium: json['is_premium'] as bool? ?? false,
    preferences: UserPreferences(
      mode: UserMode.values.byName(
        json['preferences']?['mode'] as String? ?? 'authenticated'
      ),
      settings: Map<String, dynamic>.from(
        json['preferences']?['settings'] as Map? ?? {}
      ),
    ),
  );
}