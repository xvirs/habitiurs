import 'package:equatable/equatable.dart';
import '../../domain/entities/mission.dart';

abstract class MissionEvent extends Equatable {
  const MissionEvent();

  @override
  List<Object?> get props => [];
}

class LoadMissions extends MissionEvent {
  const LoadMissions();
}

class AddMission extends MissionEvent {
  final String title;
  final String? note;
  final DateTime? dueDate;

  const AddMission({required this.title, this.note, this.dueDate});

  @override
  List<Object?> get props => [title, note, dueDate];
}

class EditMission extends MissionEvent {
  final Mission mission;

  const EditMission(this.mission);

  @override
  List<Object?> get props => [mission];
}

class ToggleMissionDone extends MissionEvent {
  final Mission mission;

  const ToggleMissionDone(this.mission);

  @override
  List<Object?> get props => [mission];
}

class RemoveMission extends MissionEvent {
  final int id;

  const RemoveMission(this.id);

  @override
  List<Object?> get props => [id];
}
