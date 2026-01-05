// lib/features/settings/domain/usecases/update_settings.dart
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  Future<void> call(AppSettings settings) async {
    await repository.updateSettings(settings);
  }
}
