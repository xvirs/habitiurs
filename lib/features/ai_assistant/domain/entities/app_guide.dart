// lib/features/ai_assistant/domain/entities/app_guide.dart
class AppGuide {
  final int id;
  final String title;
  final String content;
  final String section;
  final int order;
  final List<String> imageAssets;

  const AppGuide({
    required this.id,
    required this.title,
    required this.content,
    required this.section,
    required this.order,
    this.imageAssets = const [],
  });
}