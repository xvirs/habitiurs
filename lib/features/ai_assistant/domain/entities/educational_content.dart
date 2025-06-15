// lib/features/ai_assistant/domain/entities/educational_content.dart
class EducationalContent {
  final int id;
  final String title;
  final String content;
  final String category;
  final int readTimeMinutes;
  final DateTime createdAt;
  final bool isLocal; // true si es contenido offline

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

// lib/features/ai_assistant/domain/entities/app_guide.dart
class AppGuide {
  final int id;
  final String title;
  final String content;
  final String section; // "overview", "weekly_grid", "statistics", "best_practices"
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

// lib/features/ai_assistant/domain/entities/ai_recommendation.dart
class AIRecommendation {
  final String id;
  final String content;
  final DateTime timestamp;
  final RecommendationType type;
  final bool isFromAI; // true si viene de Gemini, false si es fallback
  final Map<String, dynamic>? context; // datos del usuario enviados

  const AIRecommendation({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.type,
    this.isFromAI = true,
    this.context,
  });
}

enum RecommendationType {
  motivation,
  improvement,
  streak,
  recovery,
  general
}

// lib/features/ai_assistant/domain/entities/user_context.dart
class UserContext {
  final List<String> habitNames;
  final Map<String, double> completionRates; // habit_name -> completion_rate
  final int currentStreak;
  final int longestStreak;
  final List<String> strugglingHabits;
  final int totalDaysTracked;
  final DateTime lastActiveDate;

  const UserContext({
    required this.habitNames,
    required this.completionRates,
    required this.currentStreak,
    required this.longestStreak,
    required this.strugglingHabits,
    required this.totalDaysTracked,
    required this.lastActiveDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'habit_names': habitNames,
      'completion_rates': completionRates,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'struggling_habits': strugglingHabits,
      'total_days_tracked': totalDaysTracked,
      'last_active_date': lastActiveDate.toIso8601String(),
    };
  }
}