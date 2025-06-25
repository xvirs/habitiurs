// lib/features/habits/presentation/bloc/habit_evaluation_state.dart
import 'package:equatable/equatable.dart';

abstract class HabitEvaluationState extends Equatable {
  const HabitEvaluationState();

  @override
  List<Object> get props => [];
}

class HabitEvaluationInitial extends HabitEvaluationState {}

class HabitEvaluationLoading extends HabitEvaluationState {
  const HabitEvaluationLoading();
}

class HabitEvaluationSuccess extends HabitEvaluationState {
  final String evaluationText;

  const HabitEvaluationSuccess(this.evaluationText);

  @override
  List<Object> get props => [evaluationText];
}

class HabitEvaluationError extends HabitEvaluationState {
  final String message;

  const HabitEvaluationError(this.message);

  @override
  List<Object> get props => [message];
}

// Opcional: Un estado para ocultar la evaluación si no hay texto o se quiere resetear
class HabitEvaluationHidden extends HabitEvaluationState {}