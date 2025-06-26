// lib/features/ai_assistant/domain/usecases/get_atomic_habits_concepts.dart
import 'package:habitiurs/shared/enums/habit_status.dart';

import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/ai_assistant_repository.dart';
import '../../../habits/domain/repositories/habit_repository.dart';
import '../../../statistics/domain/repositories/statistics_repository.dart';
import '../../../habits/domain/entities/habit.dart';
import '../../../habits/domain/entities/habit_entry.dart';

class GetAtomicHabitsConcepts {
  final AIAssistantRepository _aiAssistantRepository;
  final HabitRepository _habitRepository;
  final StatisticsRepository _statisticsRepository;

  GetAtomicHabitsConcepts({
    required AIAssistantRepository aiAssistantRepository,
    required HabitRepository habitRepository,
    required StatisticsRepository statisticsRepository,
  })  : _aiAssistantRepository = aiAssistantRepository,
        _habitRepository = habitRepository,
        _statisticsRepository = statisticsRepository;

  Future<AIResponse> call() async {
    try {
      final habits = await _habitRepository.getAllHabits();
      final allEntries = await _habitRepository.getHabitEntriesForDateRange(
        DateTime.now().subtract(const Duration(days: 365)), 
        DateTime.now(),
      );

      final userContext = {
        'habit_names': habits.map((h) => h.name).toList(),
        'current_streak': _calculateCurrentStreak(allEntries),
        'longest_streak': _calculateLongestStreak(allEntries),
        'struggling_habits': _identifyStrugglingHabits(habits, allEntries),
        'total_habits': habits.length,
      };

      final monthlyStats = await _statisticsRepository.getCurrentMonthStatistics();
      final yearlyStats = await _statisticsRepository.getCurrentYearStatistics();
      final historicalData = await _statisticsRepository.getHistoricalData();

      final statisticsContext = {
        'monthly_completion_rate': monthlyStats.completionRate,
        'total_completed_month': monthlyStats.completedCount,
        'total_skipped_month': monthlyStats.skippedCount,
        'yearly_average_rate': yearlyStats.isNotEmpty
            ? yearlyStats.map((s) => s.completionRate).reduce((a, b) => a + b) / yearlyStats.length
            : 0.0,
        'trend_direction': _getTrendDirection(historicalData),
        'total_days_tracked': _calculateTotalDaysTracked(allEntries),
      };

      return await _aiAssistantRepository.getAtomicHabitsConcepts(
        userContext: userContext,
        statisticsContext: statisticsContext,
      );
    } catch (e) {
      throw CacheFailure('Error al obtener conceptos de Hábitos Atómicos: ${e.toString()}');
    }
  }

  int _calculateCurrentStreak(List<HabitEntry> entries) {
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

  int _calculateLongestStreak(List<HabitEntry> entries) {
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

  List<String> _identifyStrugglingHabits(List<Habit> habits, List<HabitEntry> entries) {
    final Map<String, int> completedCounts = {};
    final Map<String, int> totalCounts = {};
    for (final habit in habits) {
      completedCounts[habit.name] = 0;
      totalCounts[habit.name] = 0;
    }

    for (final entry in entries) {
      final habit = habits.firstWhere((h) => h.id == entry.habitId, orElse: () => null as Habit);
      final habitName = habit?.name; 

      if (habitName != null) {
        if (entry.status == HabitStatus.completed) {
          completedCounts[habitName] = (completedCounts[habitName] ?? 0) + 1;
        }
        totalCounts[habitName] = (totalCounts[habitName] ?? 0) + 1;
      }
    }

    final List<String> struggling = [];
    totalCounts.forEach((name, total) {
      if (total > 7) {
        final rate = (completedCounts[name] ?? 0) / total;
        if (rate < 0.4) {
          struggling.add(name);
        }
      }
    });
    return struggling;
  }

  String _getTrendDirection(List historicalData) {
    if (historicalData.length < 2) return 'stable';
    return 'stable';
  }

  int _calculateTotalDaysTracked(List<HabitEntry> entries) {
    if (entries.isEmpty) return 0;
    final uniqueDates = entries.map((e) => e.date.toIso8601String().split('T')[0]).toSet();
    return uniqueDates.length;
  }
}