// lib/features/ai_assistant/presentation/bloc/ai_assistant_state.dart

import '../../../../core/ai/models/ai_response_model.dart';
import '../../domain/entities/educational_content.dart';
import '../../domain/entities/app_guide.dart';

abstract class AIAssistantState {}

class AIAssistantInitial extends AIAssistantState {}

class AIAssistantLoading extends AIAssistantState {}

class AIAssistantLoaded extends AIAssistantState {
  final List<EducationalContent> educationalContent;
  final List<AppGuide> appGuides;
  final AIResponse? currentRecommendation;
  // ✅ ELIMINADO: atomicHabitsConcepts
  // final AIResponse? atomicHabitsConcepts; 
  final bool isRecommendationLoading;
  // ✅ ELIMINADO: isAtomicConceptsLoading
  // final bool isAtomicConceptsLoading; 
  final bool hasInternetConnection;

  AIAssistantLoaded({
    required this.educationalContent,
    required this.appGuides,
    this.currentRecommendation,
    // ✅ ELIMINADO: atomicHabitsConcepts
    // this.atomicHabitsConcepts,
    this.isRecommendationLoading = false,
    // ✅ ELIMINADO: isAtomicConceptsLoading
    // this.isAtomicConceptsLoading = false, 
    this.hasInternetConnection = false,
  });

  AIAssistantLoaded copyWith({
    List<EducationalContent>? educationalContent,
    List<AppGuide>? appGuides,
    AIResponse? currentRecommendation,
    // ✅ ELIMINADO: atomicHabitsConcepts
    // AIResponse? atomicHabitsConcepts,
    bool? isRecommendationLoading,
    // ✅ ELIMINADO: isAtomicConceptsLoading
    // bool? isAtomicConceptsLoading,
    bool? hasInternetConnection,
  }) {
    return AIAssistantLoaded(
      educationalContent: educationalContent ?? this.educationalContent,
      appGuides: appGuides ?? this.appGuides,
      currentRecommendation: currentRecommendation ?? this.currentRecommendation,
      // ✅ ELIMINADO: atomicHabitsConcepts
      // atomicHabitsConcepts: atomicHabitsConcepts ?? this.atomicHabitsConcepts,
      isRecommendationLoading: isRecommendationLoading ?? this.isRecommendationLoading,
      // ✅ ELIMINADO: isAtomicConceptsLoading
      // isAtomicConceptsLoading: isAtomicConceptsLoading ?? this.isAtomicConceptsLoading,
      hasInternetConnection: hasInternetConnection ?? this.hasInternetConnection,
    );
  }
}

class AIAssistantError extends AIAssistantState {
  final String message;

  AIAssistantError(this.message);
}