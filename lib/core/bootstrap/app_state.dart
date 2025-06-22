// lib/core/bootstrap/app_state.dart - ESTADO PURO (sin widgets)
import '../errors/app_error.dart';

class AppState {
  final bool hasError;
  final AppError? error;
  final bool isInitialized;

  const AppState._({
    required this.hasError,
    this.error,
    required this.isInitialized,
  });

  // ✅ Factory constructors que retornan datos, NO widgets
  factory AppState.success() {
    return const AppState._(
      hasError: false,
      isInitialized: true,
    );
  }

  factory AppState.error({
    required String title,
    required String message,
    required String technicalDetails,
    ErrorType type = ErrorType.unknown,
  }) {
    return AppState._(
      hasError: true,
      error: AppError(
        title: title,
        message: message,
        technicalDetails: technicalDetails,
        type: type,
      ),
      isInitialized: false,
    );
  }

  // ✅ Método que retorna datos para crear AuthBloc, no lo crea aquí
  Map<String, dynamic> get authConfig {
    if (!isInitialized) {
      throw StateError('Cannot get auth config - App not initialized');
    }
    
    return {
      'initialized': isInitialized,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
