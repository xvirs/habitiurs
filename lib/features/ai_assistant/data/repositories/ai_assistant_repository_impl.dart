// lib/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart
import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/ai/models/ai_context_builder.dart';
import '../../../../core/ai/repositories/ai_repository.dart';
import '../../../habits/domain/repositories/habit_repository.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';
import '../../domain/entities/educational_content.dart';
import '../../domain/entities/app_guide.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/offline_content_datasource.dart';
import '../../domain/services/ai_assistant_prompt_builder.dart';

class AIAssistantRepositoryImpl implements AIAssistantRepository {
  final OfflineContentDatasource offlineContentDatasource;
  final AIRepository aiRepository;
  final HabitRepository habitRepository;
  final StatisticsRepository statisticsRepository;
  final AIAssistantPromptBuilder _promptBuilder;

  AIAssistantRepositoryImpl({
    required this.offlineContentDatasource,
    required this.aiRepository,
    required this.habitRepository,
    required this.statisticsRepository,
  }) : _promptBuilder = AIAssistantPromptBuilder();

  @override
  Future<List<EducationalContent>> getEducationalContent() async {
    return await offlineContentDatasource.getEducationalContent();
  }

  @override
  Future<List<EducationalContent>> getOfflineEducationalContent() async {
    return await offlineContentDatasource.getEducationalContent();
  }

  @override
  Future<List<AppGuide>> getAppGuides() async {
    return await offlineContentDatasource.getAppGuides();
  }

  @override
  Future<AIResponse> getAIRecommendation() async {
    try {
      final userContext = await _generateUserContext();
      final aiContext = AIContextBuilder.buildPersonalRecommendationContext(
        habitNames: userContext['habit_names'] ?? [],
        completionRates: Map<String, double>.from(userContext['completion_rates'] ?? {}),
        currentStreak: userContext['current_streak'] ?? 0,
        longestStreak: userContext['longest_streak'] ?? 0,
        strugglingHabits: List<String>.from(userContext['struggling_habits'] ?? []),
        totalDaysTracked: userContext['total_days_tracked'] ?? 0,
        lastActiveDate: DateTime.parse(userContext['last_active_date'] ?? DateTime.now().toIso8601String()),
      );
      final prompt = _promptBuilder.buildPersonalRecommendationPrompt(userContext);

      return await aiRepository.getPersonalizedRecommendation(prompt: prompt, metadata: aiContext);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AIResponse> getAtomicHabitsConcepts({
    required Map<String, dynamic> userContext, // No se usa directamente aquí, se regeneran.
    required Map<String, dynamic> statisticsContext, // No se usa directamente aquí, se regeneran.
  }) async {
    try {
      // ✅ MODIFICADO: Regenerar contextos dentro del repositorio para asegurar que estén actualizados.
      final latestUserContext = await _generateUserContext();
      final latestStatisticsContext = await _generateStatisticsContext();

      final prompt = _promptBuilder.buildAtomicHabitsConceptsPrompt(
        userContext: latestUserContext,
        statisticsContext: latestStatisticsContext,
      );
      final metadata = {
        ...latestUserContext,
        ...latestStatisticsContext,
        'ai_purpose': 'atomic_habits_concept',
      };
      return await aiRepository.getMotivationalMessage(
        prompt: prompt,
        metadata: metadata,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    return await aiRepository.hasInternetConnection();
  }

  Future<Map<String, dynamic>> _generateUserContext() async {
    try {
      final habits = await habitRepository.getAllHabits();
      final habitNames = habits.map((h) => h.name).toList();

      if (habits.isEmpty) {
        return {
          'habit_names': <String>[],
          'completion_rates': <String, double>{},
          'current_streak': 0,
          'longest_streak': 0,
          'struggling_habits': <String>[],
          'total_days_tracked': 0,
          'last_active_date': DateTime.now().toIso8601String(),
        };
      }

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final entries = await habitRepository.getHabitEntriesForDateRange(startDate, now);

      final completionRates = <String, double>{};
      final strugglingHabits = <String>[];
      for (final habit in habits) {
        final habitEntries = entries.where((e) => e.habitId == habit.id).toList();
        final completedCount = habitEntries.where((e) => e.status.toString() == 'HabitStatus.completed').length;
        final totalCount = habitEntries.length;

        final rate = totalCount > 0 ? completedCount / totalCount : 0.0;
        completionRates[habit.name] = rate;

        if (rate < 0.4 && totalCount > 7) {
          strugglingHabits.add(habit.name);
        }
      }

      final currentStreak = _calculateCurrentStreak(entries);
      final longestStreak = _calculateLongestStreak(entries);
      final lastActiveDate = entries.isNotEmpty
          ? entries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b)
          : now;

      return {
        'habit_names': habitNames,
        'completion_rates': completionRates,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'struggling_habits': strugglingHabits,
        'total_days_tracked': _calculateTotalDaysTracked(entries),
        'last_active_date': lastActiveDate.toIso8601String(),
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _generateStatisticsContext() async {
    try {
      final monthlyStats = await statisticsRepository.getCurrentMonthStatistics();
      final yearlyStats = await statisticsRepository.getCurrentYearStatistics();
      final historicalData = await statisticsRepository.getHistoricalData();

      return {
        'monthly_completion_rate': monthlyStats.completionRate,
        'total_completed_month': monthlyStats.completedCount,
        'total_skipped_month': monthlyStats.skippedCount,
        'yearly_average_rate': yearlyStats.isNotEmpty
            ? yearlyStats.map((s) => s.completionRate).reduce((a, b) => a + b) / yearlyStats.length
            : 0.0,
        'trend_direction': _getTrendDirection(historicalData),
      };
    } catch (e) {
      rethrow;
    }
  }

  String _getTrendDirection(List historicalData) {
    if (historicalData.length < 2) return 'stable';
    return 'stable';
  }

  int _calculateCurrentStreak(List entries) {
    if (entries.isEmpty) return 0;

    final Map<String, bool> dayCompletions = {};
    for (final entry in entries) {
      final dateStr = entry.date.toIso8601String().split('T')[0];
      if (entry.status.toString() == 'HabitStatus.completed') {
        dayCompletions[dateStr] = true;
      }
    }

    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = checkDate.toIso8601String().split('T')[0];

      if (dayCompletions[dateStr] == true) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateLongestStreak(List entries) {
    if (entries.isEmpty) return 0;

    final Map<String, bool> dayCompletions = {};
    for (final entry in entries) {
      final dateStr = entry.date.toIso8601String().split('T')[0];
      if (entry.status.toString() == 'HabitStatus.completed') {
        dayCompletions[dateStr] = true;
      }
    }

    int maxStreak = 0;
    int currentStreak = 0;
    final dates = dayCompletions.keys.map((d) => DateTime.parse(d)).toList();
    dates.sort();

    DateTime? lastDate;
    for (final date in dates) {
      final dateStr = date.toIso8601String().split('T')[0];
      if (dayCompletions[dateStr] == true) {
        if (lastDate == null || date.difference(lastDate).inDays == 1) {
          currentStreak++;
        } else {
          currentStreak = 1;
        }
        maxStreak = currentStreak > maxStreak ? currentStreak : maxStreak;
        lastDate = date;
      } else {
        currentStreak = 0;
      }
    }

    return maxStreak;
  }

  int _calculateTotalDaysTracked(List entries) {
    if (entries.isEmpty) return 0;

    final uniqueDates = entries.map((e) => e.date.toIso8601String().split('T')[0]).toSet();
    return uniqueDates.length;
  }
}