import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/core/utils/app_logger.dart';
import 'package:habitiurs/core/home_widget/home_widget_service.dart';
import 'package:habitiurs/core/notifications/notification_service.dart';

import '../../domain/entities/mission.dart';
import '../../domain/usecases/create_mission.dart';
import '../../domain/usecases/delete_mission.dart';
import '../../domain/usecases/get_missions.dart';
import '../../domain/usecases/update_mission.dart';
import 'mission_event.dart';
import 'mission_state.dart';

class MissionBloc extends Bloc<MissionEvent, MissionState> {
  final GetMissions getMissions;
  final CreateMission createMission;
  final UpdateMission updateMission;
  final DeleteMission deleteMission;

  MissionBloc({
    required this.getMissions,
    required this.createMission,
    required this.updateMission,
    required this.deleteMission,
  }) : super(const MissionInitial()) {
    on<LoadMissions>(_onLoad);
    on<AddMission>(_onAdd);
    on<EditMission>(_onEdit);
    on<ToggleMissionDone>(_onToggle);
    on<RemoveMission>(_onRemove);
  }

  Future<void> _onLoad(LoadMissions event, Emitter<MissionState> emit) async {
    try {
      // Solo mostrar "loading" en la primera carga. En recargas (cambio de
      // pestaña, volver de background, tras crear/editar) se mantiene la lista
      // actual para que no parpadee.
      if (state is! MissionLoaded) emit(const MissionLoading());
      final missions = await getMissions();
      emit(MissionLoaded(missions));
      // Refresca el widget "Pendientes" con las misiones urgentes.
      HomeWidgetService.refreshDerived();
      // Reprogramar avisos (sobrevive reinicio/reinstalación y cambios de fecha).
      for (final m in missions) {
        await _syncMissionReminder(m);
      }
    } catch (e) {
      appLog('❌ [MissionBloc] Error cargando misiones: $e');
      emit(MissionError('Error al cargar misiones: $e'));
    }
  }

  /// Programa o cancela el aviso de una misión según su estado.
  Future<void> _syncMissionReminder(Mission m) async {
    if (m.id == null) return;
    try {
      if (!m.isDone && m.dueDate != null) {
        await NotificationService().scheduleMissionReminder(
          missionId: m.id!,
          title: m.title,
          dueDate: m.dueDate!,
        );
      } else {
        await NotificationService().cancelMissionReminder(m.id!);
      }
    } catch (e) {
      appLog('⚠️ [MissionBloc] Error programando aviso de misión: $e');
    }
  }

  Future<void> _onAdd(AddMission event, Emitter<MissionState> emit) async {
    try {
      final mission = Mission(
        title: event.title.trim(),
        note: (event.note?.trim().isEmpty ?? true) ? null : event.note!.trim(),
        dueDate: event.dueDate,
        createdAt: DateTime.now(),
      );
      final id = await createMission(mission);
      await _syncMissionReminder(mission.copyWith(id: id));
      add(const LoadMissions());
    } catch (e) {
      appLog('❌ [MissionBloc] Error creando misión: $e');
      emit(MissionError('Error al crear misión: $e'));
    }
  }

  Future<void> _onEdit(EditMission event, Emitter<MissionState> emit) async {
    try {
      await updateMission(event.mission);
      await _syncMissionReminder(event.mission);
      add(const LoadMissions());
    } catch (e) {
      appLog('❌ [MissionBloc] Error editando misión: $e');
      emit(MissionError('Error al editar misión: $e'));
    }
  }

  Future<void> _onToggle(
    ToggleMissionDone event,
    Emitter<MissionState> emit,
  ) async {
    try {
      final m = event.mission;
      final nowDone = !m.isDone;
      final updated = m.copyWith(
        isDone: nowDone,
        completedAt: nowDone ? DateTime.now() : null,
        clearCompletedAt: !nowDone,
      );
      await updateMission(updated);
      // Completada → cancela el aviso; reabierta → lo reprograma.
      await _syncMissionReminder(updated);
      add(const LoadMissions());
    } catch (e) {
      appLog('❌ [MissionBloc] Error cambiando estado de misión: $e');
      emit(MissionError('Error al actualizar misión: $e'));
    }
  }

  Future<void> _onRemove(
    RemoveMission event,
    Emitter<MissionState> emit,
  ) async {
    try {
      await deleteMission(event.id);
      await NotificationService().cancelMissionReminder(event.id);
      add(const LoadMissions());
    } catch (e) {
      appLog('❌ [MissionBloc] Error eliminando misión: $e');
      emit(MissionError('Error al eliminar misión: $e'));
    }
  }
}
