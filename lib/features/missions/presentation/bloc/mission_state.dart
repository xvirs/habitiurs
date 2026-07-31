import 'package:equatable/equatable.dart';
import '../../domain/entities/mission.dart';

abstract class MissionState extends Equatable {
  const MissionState();

  @override
  List<Object?> get props => [];
}

class MissionInitial extends MissionState {
  const MissionInitial();
}

class MissionLoading extends MissionState {
  const MissionLoading();
}

class MissionLoaded extends MissionState {
  final List<Mission> missions;

  const MissionLoaded(this.missions);

  /// Pendientes primero por fecha límite (las vencidas y más próximas arriba),
  /// las sin fecha al final por orden de creación.
  List<Mission> get pending {
    final list = missions.where((m) => !m.isDone).toList();
    list.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) {
        return b.createdAt.compareTo(a.createdAt);
      }
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return list;
  }

  /// Completadas: las más recientes primero.
  List<Mission> get completed {
    final list = missions.where((m) => m.isDone).toList();
    list.sort((a, b) {
      final ac = a.completedAt ?? a.createdAt;
      final bc = b.completedAt ?? b.createdAt;
      return bc.compareTo(ac);
    });
    return list;
  }

  @override
  List<Object?> get props => [missions];
}

class MissionError extends MissionState {
  final String message;

  const MissionError(this.message);

  @override
  List<Object?> get props => [message];
}
