// lib/features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/ai_assistant/domain/usecases/get_ai_recommendation.dart';
import 'package:habitiurs/features/ai_assistant/domain/usecases/get_app_guides.dart';
import '../../domain/usecases/get_educational_content.dart';
// Mantener el import si el usecase se sigue usando en algún lado, aunque la lógica del bloc ya no.
import '../../domain/usecases/get_atomic_habits_concepts.dart'; 
import 'ai_assistant_event.dart';
import 'ai_assistant_state.dart';
import '../../../../core/errors/failures.dart'; // Importar la clase Failure

class AIAssistantBloc extends Bloc<AIAssistantEvent, AIAssistantState> {
  final GetEducationalContent getEducationalContent;
  final GetAppGuides getAppGuides;
  final GetAIRecommendation getAIRecommendation;
  // ✅ ELIMINADO: La dependencia de GetAtomicHabitsConcepts ya no es necesaria en el Bloc
  // final GetAtomicHabitsConcepts getAtomicHabitsConcepts; 

  AIAssistantBloc({
    required this.getEducationalContent,
    required this.getAppGuides,
    required this.getAIRecommendation,
    // ✅ ELIMINADO: getAtomicHabitsConcepts del constructor
    required GetAtomicHabitsConcepts getAtomicHabitsConcepts, 
  }) : super(AIAssistantInitial()) {
    on<LoadAIAssistantData>(_onLoadAIAssistantData);
    on<RefreshAIRecommendation>(_onRefreshAIRecommendation);
    on<RefreshEducationalContent>(_onRefreshEducationalContent);
    // ✅ ELIMINADO: El evento LoadAtomicHabitsConcepts y su handler
    // on<LoadAtomicHabitsConcepts>(_onLoadAtomicHabitsConcepts); 
  }

  Future<void> _onLoadAIAssistantData(
    LoadAIAssistantData event,
    Emitter<AIAssistantState> emit,
  ) async {
    print('🔄 AIAssistantBloc: Iniciando carga de datos del asistente...');
    emit(AIAssistantLoading());

    try {
      final educationalContent = await getEducationalContent();
      final appGuides = await getAppGuides();

      // Emitir un estado inicial cargado con contenido offline
      // Establece los flags de carga a true para que la UI muestre los spinners
      emit(AIAssistantLoaded(
        educationalContent: educationalContent,
        appGuides: appGuides,
        isRecommendationLoading: true, 
      ));
      print('✅ AIAssistantBloc: Contenido offline y guías cargadas.');

      // Disparar la carga de recomendación de forma asíncrona
      _loadRecommendation(emit); 

    } catch (e) {
      print('❌ AIAssistantBloc: Error general al cargar contenido del asistente (offline data): $e');
      emit(AIAssistantError('Error al cargar contenido del asistente'));
    }
  }

  Future<void> _loadRecommendation(
    Emitter<AIAssistantState> emit,
  ) async {
    // Es crucial que solo operemos si el estado actual es AIAssistantLoaded
    if (state is! AIAssistantLoaded) return; 

    AIAssistantLoaded currentState = state as AIAssistantLoaded;
    try {
      final aiRecommendationResponse = await getAIRecommendation();
      print('✅ AIAssistantBloc: Recomendación de IA cargada exitosamente.');
      emit(currentState.copyWith(
        currentRecommendation: aiRecommendationResponse,
        hasInternetConnection: aiRecommendationResponse.isFromAI,
      ));
    } on Failure catch (e) { 
      print('⚠️ AIAssistantBloc: Fallo al cargar recomendación de IA: $e. Usando fallback o sin recomendación.');
      emit(currentState.copyWith(
        currentRecommendation: null,
        hasInternetConnection: false,
      ));
    } catch (e) {
      print('❌ AIAssistantBloc: Error inesperado al cargar recomendación de IA: $e');
      emit(currentState.copyWith(
        currentRecommendation: null,
        hasInternetConnection: false,
      ));
    } finally {
      // ✅ CORRECCIÓN CLAVE: Asegurarse de que el flag de carga siempre se desactive.
      if (state is AIAssistantLoaded && (state as AIAssistantLoaded).isRecommendationLoading) {
        emit((state as AIAssistantLoaded).copyWith(isRecommendationLoading: false));
      }
    }
  }


  Future<void> _onRefreshAIRecommendation(
    RefreshAIRecommendation event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (state is AIAssistantLoaded) {
      final currentState = state as AIAssistantLoaded;
      print('🔄 AIAssistantBloc: Refrescando recomendación de IA...');

      emit(currentState.copyWith(isRecommendationLoading: true)); 

      try {
        final aiResponse = await getAIRecommendation();
        emit(currentState.copyWith(
          currentRecommendation: aiResponse,
          hasInternetConnection: aiResponse.isFromAI,
        ));
        print('✅ AIAssistantBloc: Recomendación de IA refrescada exitosamente.');
      } on Failure catch (e) { 
        print('❌ AIAssistantBloc: Error al refrescar recomendación de IA: $e');
        emit(currentState.copyWith(
          currentRecommendation: null, 
          hasInternetConnection: false,
        ));
      } catch (e) {
        print('❌ AIAssistantBloc: Error inesperado al refrescar IA: $e');
        emit(currentState.copyWith(
          currentRecommendation: null,
          hasInternetConnection: false,
        ));
      } finally {
        // ✅ CORRECCIÓN CLAVE: Asegurarse de que el flag de carga siempre se desactive.
        if (state is AIAssistantLoaded && (state as AIAssistantLoaded).isRecommendationLoading) {
          emit((state as AIAssistantLoaded).copyWith(isRecommendationLoading: false));
        }
      }
    }
  }

  Future<void> _onRefreshEducationalContent(
    RefreshEducationalContent event,
    Emitter<AIAssistantState> emit,
  ) async {
    if (state is AIAssistantLoaded) {
      final currentState = state as AIAssistantLoaded;
      print('🔄 AIAssistantBloc: Refrescando contenido educativo offline...');

      try {
        final educationalContent = await getEducationalContent();
        emit(currentState.copyWith(
          educationalContent: educationalContent,
        ));
        print('✅ AIAssistantBloc: Contenido educativo refrescado.');
      } catch (e) {
        print('❌ AIAssistantBloc: Error al refrescar contenido educativo: $e');
      }
    }
  }

  // ✅ ELIMINADO: _onLoadAtomicHabitsConcepts ya no es necesario
  // Future<void> _onLoadAtomicHabitsConcepts(...) { ... }
}