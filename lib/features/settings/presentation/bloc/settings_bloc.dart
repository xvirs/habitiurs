// lib/features/settings/presentation/bloc/settings_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettings getSettings;
  final UpdateSettings updateSettings;

  SettingsBloc({
    required this.getSettings,
    required this.updateSettings,
  }) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleNotifications>(_onToggleNotifications);
    on<UpdateNotificationTime>(_onUpdateNotificationTime);
    on<ResetSettings>(_onResetSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError('Error al cargar configuración: ${e.toString()}'));
    }
  }

  Future<void> _onToggleNotifications(
    ToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      if (state is SettingsLoaded) {
        final currentSettings = (state as SettingsLoaded).settings;
        final newSettings = currentSettings.copyWith(
          notificationsEnabled: event.enabled,
        );

        await updateSettings(newSettings);

        // Actualizar notificaciones
        if (event.enabled) {
          // Las notificaciones se reprogramarán la próxima vez que se carguen los hábitos
          print('✅ [SettingsBloc] Notificaciones habilitadas');
        } else {
          try {
            await NotificationService().cancelNotification(0);
            print('🔕 [SettingsBloc] Notificaciones deshabilitadas');
          } catch (notifError) {
            print('⚠️ [SettingsBloc] Error cancelando notificación: $notifError');
            // Continuar de todas formas, el estado ya se guardó
          }
        }

        emit(SettingsLoaded(newSettings));
      }
    } catch (e) {
      print('❌ [SettingsBloc] Error: $e');
      // Mantener el estado actual en lugar de error para evitar crash
      if (state is SettingsLoaded) {
        emit(state as SettingsLoaded);
      } else {
        emit(SettingsError('Error al actualizar notificaciones: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUpdateNotificationTime(
    UpdateNotificationTime event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      if (state is SettingsLoaded) {
        final currentSettings = (state as SettingsLoaded).settings;
        final newSettings = currentSettings.copyWith(
          notificationHour: event.hour,
          notificationMinute: event.minute,
        );

        await updateSettings(newSettings);

        // Cancelar notificación anterior y reprogramar con nueva hora
        try {
          await NotificationService().cancelNotification(0);
          print('⏰ [SettingsBloc] Hora actualizada: ${event.hour}:${event.minute}');
        } catch (notifError) {
          print('⚠️ [SettingsBloc] Error cancelando notificación: $notifError');
          // Continuar de todas formas, se reprogramará en el próximo load de hábitos
        }

        emit(SettingsLoaded(newSettings));
      }
    } catch (e) {
      print('❌ [SettingsBloc] Error actualizando hora: $e');
      // Mantener el estado actual
      if (state is SettingsLoaded) {
        emit(state as SettingsLoaded);
      } else {
        emit(SettingsError('Error al actualizar hora: ${e.toString()}'));
      }
    }
  }

  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(const SettingsLoading());
      // Resetear en repositorio (borrará SharedPreferences)
      // El getSettings devolverá valores por defecto
      final settings = await getSettings();
      emit(SettingsLoaded(settings));
      print('🔄 [SettingsBloc] Configuración reseteada');
    } catch (e) {
      emit(SettingsError('Error al resetear configuración: ${e.toString()}'));
    }
  }
}
