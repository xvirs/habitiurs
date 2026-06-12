// lib/features/settings/data/repositories/settings_repository_impl.dart
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/app_settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDatasource localDatasource;

  SettingsRepositoryImpl({required this.localDatasource});

  @override
  Future<AppSettings> getSettings() async {
    final model = await localDatasource.getSettings();
    final minStr = model.notificationMinute.toString().padLeft(2, '0');
    print('⚙️ [Settings] Configuración cargada — notificaciones: ${model.notificationsEnabled}, hora: ${model.notificationHour}:$minStr');
    return model.toEntity();
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    final model = AppSettingsModel.fromEntity(settings);
    await localDatasource.saveSettings(model);
    final minStr = settings.notificationMinute.toString().padLeft(2, '0');
    print('✅ [Settings] Configuración guardada — notificaciones: ${settings.notificationsEnabled}, hora: ${settings.notificationHour}:$minStr');
  }

  @override
  Future<void> resetToDefaults() async {
    await localDatasource.clearSettings();
    print('🔄 [Settings] Configuración restablecida a valores por defecto');
  }
}
