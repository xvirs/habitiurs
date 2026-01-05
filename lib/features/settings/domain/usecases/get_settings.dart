// lib/features/settings/domain/usecases/get_settings.dart
import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  final SettingsRepository repository;

  GetSettings(this.repository);

  Future<AppSettings> call() async {
    return await repository.getSettings();
  }
}
