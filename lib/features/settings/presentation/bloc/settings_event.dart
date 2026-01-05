// lib/features/settings/presentation/bloc/settings_event.dart
import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class ToggleNotifications extends SettingsEvent {
  final bool enabled;

  const ToggleNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateNotificationTime extends SettingsEvent {
  final int hour;
  final int minute;

  const UpdateNotificationTime(this.hour, this.minute);

  @override
  List<Object?> get props => [hour, minute];
}

class ResetSettings extends SettingsEvent {
  const ResetSettings();
}
