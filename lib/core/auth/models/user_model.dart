// lib/core/auth/models/user_model.dart
class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isPremium;
  final Map<String, dynamic> preferences;

  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.lastLogin,
    this.isPremium = false,
    this.preferences = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoURL,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
      'is_premium': isPremium,
      'preferences': preferences,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      displayName: json['display_name'],
      photoURL: json['photo_url'],
      createdAt: DateTime.parse(json['created_at']),
      lastLogin: DateTime.parse(json['last_login']),
      isPremium: json['is_premium'] ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isPremium,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isPremium: isPremium ?? this.isPremium,
      preferences: preferences ?? this.preferences,
    );
  }
}


