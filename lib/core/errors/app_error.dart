// lib/core/errors/app_error.dart - MODELO PURO (sin UI)
class AppError {
  final String title;
  final String message;
  final String technicalDetails;
  final DateTime timestamp;
  final ErrorType type;

  AppError({
    required this.title,
    required this.message,
    required this.technicalDetails,
    DateTime? timestamp,
    this.type = ErrorType.unknown,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'AppError: $title - $message';
}

enum ErrorType { initialization, network, authentication, permission, unknown }
