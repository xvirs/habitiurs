// lib/core/settings/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitiurs/core/utils/app_logger.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // Keys para SharedPreferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationHourKey = 'notification_hour';
  static const String _notificationMinuteKey = 'notification_minute';

  // Valores por defecto
  static const bool _defaultNotificationsEnabled = true;
  static const int _defaultNotificationHour = 20; // 8 PM
  static const int _defaultNotificationMinute = 0;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    appLog('✅ [SettingsService] Inicializado');
  }

  // Getters
  bool get notificationsEnabled {
    return _prefs?.getBool(_notificationsEnabledKey) ?? _defaultNotificationsEnabled;
  }

  int get notificationHour {
    return _prefs?.getInt(_notificationHourKey) ?? _defaultNotificationHour;
  }

  int get notificationMinute {
    return _prefs?.getInt(_notificationMinuteKey) ?? _defaultNotificationMinute;
  }

  // Setters
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_notificationsEnabledKey, enabled);
    appLog('💾 [SettingsService] Notificaciones ${enabled ? 'habilitadas' : 'deshabilitadas'}');
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    await _prefs?.setInt(_notificationHourKey, hour);
    await _prefs?.setInt(_notificationMinuteKey, minute);
    appLog('💾 [SettingsService] Hora de notificación: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
  }

  // Resetear a valores por defecto
  Future<void> resetToDefaults() async {
    await setNotificationsEnabled(_defaultNotificationsEnabled);
    await setNotificationTime(_defaultNotificationHour, _defaultNotificationMinute);
    appLog('🔄 [SettingsService] Configuración reseteada a valores por defecto');
  }
}
