// lib/features/ai_assistant/presentation/bloc/ai_assistant_event.dart
import 'package:equatable/equatable.dart';

abstract class AIAssistantEvent extends Equatable {
  const AIAssistantEvent();

  @override
  List<Object> get props => [];
}

class LoadAIAssistantData extends AIAssistantEvent {}

class RefreshAIRecommendation extends AIAssistantEvent {}

class RefreshEducationalContent extends AIAssistantEvent {}

// ✅ ELIMINADO: El evento LoadAtomicHabitsConcepts
// class LoadAtomicHabitsConcepts extends AIAssistantEvent {
//   const LoadAtomicHabitsConcepts();
//   @override
//   List<Object> get props => [];
// }

class PullToRefreshAIAssistant extends AIAssistantEvent {}