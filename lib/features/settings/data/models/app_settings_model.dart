// lib/features/settings/data/models/app_settings_model.dart
import '../../domain/entities/app_settings.dart';

class AppSettingsModel extends AppSettings {
  const AppSettingsModel({
    required super.notificationsEnabled,
    required super.notificationHour,
    required super.notificationMinute,
  });

  factory AppSettingsModel.fromEntity(AppSettings settings) {
    return AppSettingsModel(
      notificationsEnabled: settings.notificationsEnabled,
      notificationHour: settings.notificationHour,
      notificationMinute: settings.notificationMinute,
    );
  }

  AppSettings toEntity() {
    return AppSettings(
      notificationsEnabled: notificationsEnabled,
      notificationHour: notificationHour,
      notificationMinute: notificationMinute,
    );
  }
}
