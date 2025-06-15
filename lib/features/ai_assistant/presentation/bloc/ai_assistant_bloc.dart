// lib/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_educational_content.dart';
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';

class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final GetEducationalContent getEducationalContent;
  final GetAppGuides getAppGuides;
  final GetAIRecommendation getAIRecommendation;

  AIAssistantBloc({
    required this.getEducationalContent,
    required this.getAppGuides,
    required this.getAIRecommendation,
  }) : super(AIAssistantInitial()) {
    on<LoadAIAssistantData>(_onLoadAIAssistantData);
    on<RefreshAIRecommendation>(_onRefreshAIRecommendation);
    on<RefreshEducationalContent>(_onRefreshEducationalContent);
  }

  Future<void> _onLoadAIAssistantData(
    LoadAIAssistantData event,
    Emitter<AIAssistantState> emit,
  ) async {
    emit(AIAssistantLoading());
    
    try {
      // Cargar contenido offline primero (rápido)
      final educationalContent = await getEducationalContent();
      final appGuides = await getAppGuides();
      
      // Emitir estado inicial con contenido offline
      emit(AIAssistantLoaded(
        educationalContent: educationalContent,
        appGuides: appGuides,
        isRecommendationLoading: true,
      ));

      // Luego intentar cargar recomendación de IA (puede tomar tiempo)
      try {
        final recommendation = await getAIRecommendation();
        
        emit(AIAssistantLoaded(
          educationalContent: educationalContent,
          appGuides: appGuides,
          currentRecommendation: recommendation,
          isRecommendationLoading: false,
          hasInternetConnection: recommendation.isFromAI,
        ));
      } catch (e) {
        // Si falla la IA, mantener el estado pero sin recomendación
        emit(AIAssistantLoaded(
          educationalContent: educationalContent,
          appGuides: appGuides,
          isRecommendationLoading: false,
          hasInternetConnection: false,
        ));
      }
    } catch (e) {
      emit(AIAssistantError('Error al cargar contenido del asistente'));
    }
  }

  Future<void> _onRefreshAIRecommendation(
    RefreshAIRecommendation event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (state is AIAssistantLoaded) {
      final currentState = state as AIAssistantLoaded;
      
      // Mostrar loading para la recomendación
      emit(currentState.copyWith(isRecommendationLoading: true));
      
      try {
        final recommendation = await getAIRecommendation();
        
        emit(currentState.copyWith(
          currentRecommendation: recommendation,
          isRecommendationLoading: false,
          hasInternetConnection: recommendation.isFromAI,
        ));
      } catch (e) {
        // Si falla, mantener estado anterior pero sin loading
        emit(currentState.copyWith(
          isRecommendationLoading: false,
          hasInternetConnection: false,
        ));
      }
    }
  }

  Future<void> _onRefreshEducationalContent(
    RefreshEducationalContent event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (state is AIAssistantLoaded) {
      final currentState = state as AIAssistantLoaded;
      
      try {
        final educationalContent = await getEducationalContent();
        
        emit(currentState.copyWith(
          educationalContent: educationalContent,
        ));
      } catch (e) {
        // Mantener contenido anterior si falla
      }
    }
  }
}