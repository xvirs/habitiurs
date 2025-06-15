// lib/features/ai_assistant/presentation/bloc/ai_assistant_state.dart
import '../../domain/entities/educational_content.dart';

abstract class AIAssistantState {}

class AIAssistantInitial extends AIAssistantState {}

class AIAssistantLoading extends AIAssistantState {}

class AIAssistantLoaded extends AIAssistantState {
  final List<EducationalContent> educationalContent;
  final List<AppGuide> appGuides;
  final AIRecommendation? currentRecommendation;
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
    AIRecommendation? currentRecommendation,
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