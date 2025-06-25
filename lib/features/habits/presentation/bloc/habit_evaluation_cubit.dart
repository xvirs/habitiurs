// lib/features/habits/presentation/bloc/habit_evaluation_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/ai/repositories/ai_repository.dart'; // Asegúrate de que esta ruta sea correcta
import 'habit_evaluation_state.dart'; // Asegúrate de que esta ruta sea correcta

class HabitEvaluationCubit extends Cubit<HabitEvaluationState> {
  final AIRepository _aiRepository;

  HabitEvaluationCubit({required AIRepository aiRepository})
      : _aiRepository = aiRepository,
        super(HabitEvaluationInitial());

  Future<void> evaluateHabit(String habitDescription) async {
    if (habitDescription.trim().isEmpty) {
      emit(const HabitEvaluationError('La descripción del hábito no puede estar vacía.'));
      return;
    }

    emit(const HabitEvaluationLoading());
    try {
      final aiResponse = await _aiRepository.evaluateHabit(habitDescription);
      emit(HabitEvaluationSuccess(aiResponse.content));
    } catch (e) {
      print('❌ [HabitEvaluationCubit] Error al evaluar hábito: $e');
      emit(HabitEvaluationError('Error al obtener evaluación de IA. Intenta de nuevo: ${e.toString()}'));
    }
  }

  void hideEvaluation() {
    emit(HabitEvaluationHidden());
  }

  void resetEvaluation() {
    emit(HabitEvaluationInitial());
  }
}