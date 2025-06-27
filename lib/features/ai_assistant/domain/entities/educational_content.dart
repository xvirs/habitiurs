// lib/features/ai_assistant/domain/entities/educational_content.dart
class EducationalContent {
  final int id;
  final String title;
  final String content;
  final String category;
  final int readTimeMinutes;
  final DateTime createdAt;
  final bool isLocal;

  const EducationalContent({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.readTimeMinutes,
    required this.createdAt,
    this.isLocal = false,
  });
}