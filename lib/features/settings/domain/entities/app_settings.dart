// lib/features/settings/domain/entities/app_settings.dart
import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final bool notificationsEnabled;
  final int notificationHour;
  final int notificationMinute;

  const AppSettings({
    required this.notificationsEnabled,
    required this.notificationHour,
    required this.notificationMinute,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      notificationsEnabled: true,
      notificationHour: 20, // 8 PM
      notificationMinute: 0,
    );
  }

  String get formattedNotificationTime {
    return '${notificationHour.toString().padLeft(2, '0')}:${notificationMinute.toString().padLeft(2, '0')}';
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
    );
  }

  @override
  List<Object?> get props => [
        notificationsEnabled,
        notificationHour,
        notificationMinute,
      ];
}
