// lib/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart
import '../../domain/entities/educational_content.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/offline_content_datasource.dart';
import '../services/gemini_api_service.dart';
import '../../../habits/domain/repositories/habit_repository.dart';

class AIAssistantRepositoryImpl implements AIAssistantRepository {
  final OfflineContentDatasource offlineContentDatasource;
  final GeminiApiService geminiApiService;
  final HabitRepository habitRepository;

  AIAssistantRepositoryImpl({
    required this.offlineContentDatasource,
    required this.geminiApiService,
    required this.habitRepository,
  });

  @override
  Future<List<EducationalContent>> getEducationalContent() async {
    // Por ahora, siempre usar contenido offline
    // En el futuro se podría agregar contenido dinámico desde una API
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
  Future<AIRecommendation> getAIRecommendation(UserContext context) async {
    return await geminiApiService.getRecommendation(context);
  }

  @override
  Future<List<AIRecommendation>> getFallbackRecommendations() async {
    return await offlineContentDatasource.getFallbackRecommendations();
  }

  @override
  Future<UserContext> generateUserContext() async {
    try {
      // Obtener todos los hábitos
      final habits = await habitRepository.getAllHabits();
      final habitNames = habits.map((h) => h.name).toList();

      if (habits.isEmpty) {
        return UserContext(
          habitNames: [],
          completionRates: {},
          currentStreak: 0,
          longestStreak: 0,
          strugglingHabits: [],
          totalDaysTracked: 0,
          lastActiveDate: DateTime.now(),
        );
      }

      // Obtener entradas de los últimos 30 días
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final entries = await habitRepository.getHabitEntriesForDateRange(startDate, now);

      // Calcular tasas de cumplimiento por hábito
      final completionRates = <String, double>{};
      final strugglingHabits = <String>[];

      for (final habit in habits) {
        final habitEntries = entries.where((e) => e.habitId == habit.id).toList();
        final completedCount = habitEntries.where((e) => e.status.toString() == 'HabitStatus.completed').length;
        final totalCount = habitEntries.length;
        
        final rate = totalCount > 0 ? completedCount / totalCount : 0.0;
        completionRates[habit.name] = rate;
        
        if (rate < 0.4 && totalCount > 7) { // Considerarlo "struggling" si <40% y al menos 7 días de datos
          strugglingHabits.add(habit.name);
        }
      }

      // Calcular rachas
      final currentStreak = _calculateCurrentStreak(entries);
      final longestStreak = _calculateLongestStreak(entries);

      // Última fecha activa
      final lastActiveDate = entries.isNotEmpty 
          ? entries.map((e) => e.date).reduce((a, b) => a.isAfter(b) ? a : b)
          : now;

      return UserContext(
        habitNames: habitNames,
        completionRates: completionRates,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        strugglingHabits: strugglingHabits,
        totalDaysTracked: _calculateTotalDaysTracked(entries),
        lastActiveDate: lastActiveDate,
      );
    } catch (e) {
      // En caso de error, devolver contexto vacío
      return UserContext(
        habitNames: [],
        completionRates: {},
        currentStreak: 0,
        longestStreak: 0,
        strugglingHabits: [],
        totalDaysTracked: 0,
        lastActiveDate: DateTime.now(),
      );
    }
  }

  @override
  Future<bool> hasInternetConnection() async {
    return await geminiApiService.checkConnectivity();
  }

  int _calculateCurrentStreak(List entries) {
    if (entries.isEmpty) return 0;

    // Agrupar por fecha y verificar si al menos un hábito fue completado cada día
    final Map<String, bool> dayCompletions = {};
    
    for (final entry in entries) {
      final dateStr = entry.date.toIso8601String().split('T')[0];
      if (entry.status.toString() == 'HabitStatus.completed') {
        dayCompletions[dateStr] = true;
      }
    }

    // Calcular racha actual (días consecutivos con al menos un hábito completado)
    int streak = 0;
    final today = DateTime.now();
    
    for (int i = 0; i < 365; i++) { // Máximo 365 días hacia atrás
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

    // Similar al actual pero buscar la racha más larga en todo el historial
    final Map<String, bool> dayCompletions = {};
    
    for (final entry in entries) {
      final dateStr = entry.date.toIso8601String().split('T')[0];
      if (entry.status.toString() == 'HabitStatus.completed') {
        dayCompletions[dateStr] = true;
      }
    }

    int maxStreak = 0;
    int currentStreak = 0;
    
    // Obtener todas las fechas únicas y ordenarlas
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
    
    // Contar días únicos con al menos una entrada
    final uniqueDates = entries.map((e) => e.date.toIso8601String().split('T')[0]).toSet();
    return uniqueDates.length;
  }
}