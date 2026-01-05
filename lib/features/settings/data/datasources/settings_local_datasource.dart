// lib/features/settings/data/datasources/settings_local_datasource.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings_model.dart';

abstract class SettingsLocalDatasource {
  Future<AppSettingsModel> getSettings();
  Future<void> saveSettings(AppSettingsModel settings);
  Future<void> clearSettings();
}

class SettingsLocalDatasourceImpl implements SettingsLocalDatasource {
  final SharedPreferences sharedPreferences;

  // Keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';

  SettingsLocalDatasourceImpl({required this.sharedPreferences});

  @override
  Future<AppSettingsModel> getSettings() async {
    final notificationsEnabled = sharedPreferences.getBool(_notificationsEnabledKey) ?? true;
    final notificationHour = sharedPreferences.getInt(_notificationHourKey) ?? 20;
    final notificationMinute = sharedPreferences.getInt(_notificationMinuteKey) ?? 0;

    return AppSettingsModel(
      notificationsEnabled: notificationsEnabled,
      notificationHour: notificationHour,
      notificationMinute: notificationMinute,
    );
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    await sharedPreferences.setBool(_notificationsEnabledKey, settings.notificationsEnabled);
    await sharedPreferences.setInt(_notificationHourKey, settings.notificationHour);
    await sharedPreferences.setInt(_notificationMinuteKey, settings.notificationMinute);
  }

  @override
  Future<void> clearSettings() async {
    await sharedPreferences.remove(_notificationsEnabledKey);
    await sharedPreferences.remove(_notificationHourKey);
    await sharedPreferences.remove(_notificationMinuteKey);
  }
}
