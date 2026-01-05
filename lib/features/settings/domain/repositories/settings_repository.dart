// lib/features/settings/domain/repositories/settings_repository.dart
import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> resetToDefaults();
}
