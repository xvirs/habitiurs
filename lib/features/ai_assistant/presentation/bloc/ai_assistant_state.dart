// lib/features/ai_assistant/presentation/bloc/ai_assistant_state.dart
// 🔄 REFACTORIZADO - Usar AIResponse del core en lugar de AIRecommendation

import '../../../../core/ai/models/ai_response_model.dart';
import '../../domain/entities/educational_content.dart';
import '../../domain/entities/app_guide.dart';

abstract class AIAssistantState {}

class AIAssistantInitial extends AIAssistantState {}

class AIAssistantLoading extends AIAssistantState {}

class AIAssistantLoaded extends AIAssistantState {
  final List<EducationalContent> educationalContent;
  final List<AppGuide> appGuides;
  final AIResponse? currentRecommendation; // ✅ Cambiado de AIRecommendation a AIResponse
  final bool isRecommendationLoading;
  final bool hasInternetConnection;

  AIAssistantLoaded({
    required this.educationalContent,
    required this.appGuides,
    this.currentRecommendation,
    this.isRecommendationLoading = false,
    this.hasInternetConnection = false,
  });

  AIAssistantLoaded copyWith({
    List<EducationalContent>? educationalContent,
    List<AppGuide>? appGuides,
    AIResponse? currentRecommendation, // ✅ Cambiado de AIRecommendation a AIResponse
    bool? isRecommendationLoading,
    bool? hasInternetConnection,
  }) {
    return AIAssistantLoaded(
      educationalContent: educationalContent ?? this.educationalContent,
      appGuides: appGuides ?? this.appGuides,
      currentRecommendation: currentRecommendation ?? this.currentRecommendation,
      isRecommendationLoading: isRecommendationLoading ?? this.isRecommendationLoading,
      hasInternetConnection: hasInternetConnection ?? this.hasInternetConnection,
    );
  }
}

class AIAssistantError extends AIAssistantState {
  final String message;

  AIAssistantError(this.message);
}