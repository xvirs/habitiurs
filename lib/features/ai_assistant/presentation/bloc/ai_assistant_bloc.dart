// lib/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_ai_recommendation.dart';
import '../../domain/usecases/get_app_guides.dart';
import '../../domain/usecases/get_educational_content.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final GetEducationalContent _getEducationalContent;
  final GetAppGuides _getAppGuides;
  final GetAIRecommendation _getAIRecommendation;

  AIAssistantBloc({
    required GetEducationalContent getEducationalContent,
    required GetAppGuides getAppGuides,
    required GetAIRecommendation getAIRecommendation,
  })  : _getEducationalContent = getEducationalContent,
        _getAppGuides = getAppGuides,
        _getAIRecommendation = getAIRecommendation,
        super(AIAssistantInitial()) {
    on<LoadAIAssistantData>(_onLoadAIAssistantData);
    on<RefreshAIRecommendation>(_onRefreshAIRecommendation);
  }

  Future<void> _onLoadAIAssistantData(
    LoadAIAssistantData event,
    Emitter<AIAssistantState> emit,
  ) async {
    print('🔄 [AIAssistantBloc] Cargando contenido del asistente IA...');
    emit(AIAssistantLoading());

    try {
      final educationalContent = await _getEducationalContent();
      final appGuides = await _getAppGuides();
      print('✅ [AIAssistantBloc] Contenido educativo (${educationalContent.length}) y guías (${appGuides.length}) cargados');

      emit(AIAssistantLoaded(
        educationalContent: educationalContent,
        appGuides: appGuides,
        isRecommendationLoading: true,
      ));

      print('🤖 [AIAssistantBloc] Solicitando recomendación personalizada a IA...');
      try {
        final aiResponse = await _getAIRecommendation();
        print('✅ [AIAssistantBloc] Recomendación obtenida — fuente: ${aiResponse.isFromAI ? 'Gemini IA' : 'fallback local'}');

        emit(AIAssistantLoaded(
          educationalContent: educationalContent,
          appGuides: appGuides,
          currentRecommendation: aiResponse,
          isRecommendationLoading: false,
          hasInternetConnection: aiResponse.isFromAI,
        ));
      } catch (e) {
        print('⚠️ [AIAssistantBloc] No se pudo obtener recomendación IA: $e');
        emit(AIAssistantLoaded(
          educationalContent: educationalContent,
          appGuides: appGuides,
          isRecommendationLoading: false,
          hasInternetConnection: false,
        ));
      }
    } catch (e) {
      print('❌ [AIAssistantBloc] Error al cargar contenido del asistente: $e');
      emit(AIAssistantError('Error al cargar contenido del asistente'));
    }
  }

  Future<void> _onRefreshAIRecommendation(
    RefreshAIRecommendation event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (state is AIAssistantLoaded) {
      final currentState = state as AIAssistantLoaded;
      print('🔄 [AIAssistantBloc] Actualizando recomendación IA...');
      emit(currentState.copyWith(isRecommendationLoading: true));

      try {
        final aiResponse = await _getAIRecommendation();
        print('✅ [AIAssistantBloc] Recomendación actualizada — fuente: ${aiResponse.isFromAI ? 'Gemini IA' : 'fallback local'}');

        emit(currentState.copyWith(
          currentRecommendation: aiResponse,
          isRecommendationLoading: false,
          hasInternetConnection: aiResponse.isFromAI,
        ));
      } catch (e) {
        print('❌ [AIAssistantBloc] Error al actualizar recomendación: $e');
        emit(currentState.copyWith(
          isRecommendationLoading: false,
          hasInternetConnection: false,
        ));
      }
    }
  }
}