import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/ai/repositories/ai_repository.dart';
import 'habit_evaluation_state.dart';
import '../../domain/services/habit_ai_prompt_builder.dart';

class HabitEvaluationCubit extends Cubit<HabitEvaluationState> {
  final AIRepository _aiRepository;
  final HabitAIPromptBuilder _promptBuilder;

  HabitEvaluationCubit({required AIRepository aiRepository})
      : _aiRepository = aiRepository,
        _promptBuilder = HabitAIPromptBuilder(),
        super(HabitEvaluationInitial());

  Future<void> evaluateHabit(String habitDescription) async {
    if (habitDescription.trim().isEmpty) {
      emit(const HabitEvaluationError('La descripción del hábito no puede estar vacía.'));
      return;
    }

    emit(const HabitEvaluationLoading());
    try {
      final prompt = _promptBuilder.buildHabitEvaluationPrompt(habitDescription);
      final metadata = {'habit': habitDescription};

      final aiResponse = await _aiRepository.evaluateHabit(
        prompt: prompt,
        metadata: metadata,
      );
      emit(HabitEvaluationSuccess(aiResponse.content));
    } catch (e) {
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
