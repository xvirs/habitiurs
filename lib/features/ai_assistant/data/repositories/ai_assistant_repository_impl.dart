// lib/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart
import '../../../../core/ai/models/ai_request_model.dart';
import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/ai/models/ai_context_builder.dart';
import '../../../../core/ai/repositories/ai_repository.dart';
import '../../../../shared/enums/habit_status.dart';
import '../../../habits/domain/repositories/habit_repository.dart';
import '../../domain/entities/educational_content.dart';
import '../../domain/entities/app_guide.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../../domain/services/ai_prompt_service.dart';
import '../datasources/offline_content_datasource.dart';

class AIAssistantRepositoryImpl implements AIAssistantRepository {
  final OfflineContentDatasource _offlineContentDatasource;
  final AIRepository _aiRepository;
  final HabitRepository _habitRepository;

  AIAssistantRepositoryImpl({
    required OfflineContentDatasource offlineContentDatasource,
    required AIRepository aiRepository,
    required HabitRepository habitRepository,
  })  : _offlineContentDatasource = offlineContentDatasource,
        _aiRepository = aiRepository,
        _habitRepository = habitRepository;

  @override
  Future<List<EducationalContent>> getEducationalContent() async {
    return await _offlineContentDatasource.getEducationalContent();
  }

  @override
  Future<List<EducationalContent>> getOfflineEducationalContent() async {
    return await _offlineContentDatasource.getEducationalContent();
  }

  @override
  Future<List<AppGuide>> getAppGuides() async {
    return await _offlineContentDatasource.getAppGuides();
  }

  @override
  Future<AIResponse> getAIRecommendation() async {
    print('🤖 [AIAssistant] Generando contexto de usuario...');
    try {
      final userContext = await _generateUserContext();
      print('🤖 [AIAssistant] Contexto listo — hábitos: ${(userContext['habit_names'] as List?)?.length ?? 0}, racha actual: ${userContext['current_streak']}, días rastreados: ${userContext['total_days_tracked']}');

      final aiContext = AIContextBuilder.buildPersonalRecommendationContext(
        habitNames: userContext['habit_names'] ?? [],
        completionRates: Map<String, double>.from(userContext['completion_rates'] ?? {}),
        currentStreak: userContext['current_streak'] ?? 0,
        longestStreak: userContext['longest_streak'] ?? 0,
        strugglingHabits: List<String>.from(userContext['struggling_habits'] ?? []),
        totalDaysTracked: userContext['total_days_tracked'] ?? 0,
        lastActiveDate: DateTime.parse(userContext['last_active_date'] ?? DateTime.now().toIso8601String()),
      );

      final request = AIRequest(
        type: AIRequestType.personalRecommendation,
        prompt: AIPromptService.buildPersonalRecommendationPrompt(
          habitNames: userContext['habit_names'] ?? [],
          completionRates: Map<String, double>.from(userContext['completion_rates'] ?? {}),
          currentStreak: userContext['current_streak'] ?? 0,
          strugglingHabits: List<String>.from(userContext['struggling_habits'] ?? []),
        ),
        metadata: aiContext,
      );

      return await _aiRepository.generateResponse(request);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    return await _aiRepository.hasInternetConnection();
  }

  Future<Map<String, dynamic>> _generateUserContext() async {
    try {
      final habits = await _habitRepository.getAllHabits();
      final habitNames = habits.map((h) => h.name).toList();

      if (habits.isEmpty) {
        return _getEmptyContext();
      }

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final entries = await _habitRepository.getHabitEntriesForDateRange(startDate, now);

      final completionRates = <String, double>{};
      final strugglingHabits = <String>[];

      for (final habit in habits) {
        final habitEntries = entries.where((e) => e.habitId == habit.id).toList();
        final completedCount = habitEntries.where((e) => e.status == HabitStatus.completed).length;
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
      return _getEmptyContext();
    }
  }

  Map<String, dynamic> _getEmptyContext() {
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

  int _calculateCurrentStreak(List entries) {
    if (entries.isEmpty) return 0;

    final Map<String, bool> dayCompletions = {};

    for (final entry in entries) {
      final dateStr = entry.date.toIso8601String().split('T')[0];
      if (entry.status == HabitStatus.completed) {
        dayCompletions[dateStr] = true;
      }
    }

    int streak = 0;
    final today = DateTime.now();
    // If today has no completion yet, the streak is still alive from yesterday —
    // don't penalize users who haven't completed habits yet today.
    final todayStr = today.toIso8601String().split('T')[0];
    final startOffset = dayCompletions[todayStr] == true ? 0 : 1;

    for (int i = startOffset; i < 365; i++) {
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
      if (entry.status == HabitStatus.completed) {
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