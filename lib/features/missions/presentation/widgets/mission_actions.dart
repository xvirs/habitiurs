import 'package:flutter/material.dart';
import 'package:habitiurs/core/service/vibration_service.dart';

import '../../domain/entities/mission.dart';
import '../bloc/mission_bloc.dart';
import '../bloc/mission_event.dart';

/// Acciones de misión compartidas (banner, pestaña, tablero) con "Deshacer".

/// Completa o reabre una misión mostrando un SnackBar con opción de deshacer.
void toggleMissionWithUndo(
  BuildContext context,
  MissionBloc bloc,
  Mission mission,
) {
  final wasDone = mission.isDone;
  bloc.add(ToggleMissionDone(mission));
  // Feedback háptico: completar se siente como un logro.
  if (wasDone) {
    VibrationService.selection();
  } else {
    VibrationService.success();
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(wasDone ? 'Misión reabierta' : 'Misión completada'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Deshacer',
          // Restaura el estado original exacto (isDone/completedAt).
          onPressed: () => bloc.add(EditMission(mission)),
        ),
      ),
    );
}

/// Borra (tombstone) una misión mostrando un SnackBar con opción de deshacer.
void deleteMissionWithUndo(
  BuildContext context,
  MissionBloc bloc,
  Mission mission,
) {
  if (mission.id == null) return;
  bloc.add(RemoveMission(mission.id!));

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Misión "${mission.title}" eliminada'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Deshacer',
          // Reactiva la fila borrada (is_deleted=0) conservando su id/historial.
          onPressed:
              () => bloc.add(
                EditMission(
                  mission.copyWith(
                    isDeleted: false,
                    lastModified: DateTime.now(),
                  ),
                ),
              ),
        ),
      ),
    );
}
