// lib/features/ai_assistant/presentation/bloc/ai_assistant_event.dart
abstract class AIAssistantEvent {}

class LoadAIAssistantData extends AIAssistantEvent {}

class RefreshAIRecommendation extends AIAssistantEvent {}

class RefreshEducationalContent extends AIAssistantEvent {}