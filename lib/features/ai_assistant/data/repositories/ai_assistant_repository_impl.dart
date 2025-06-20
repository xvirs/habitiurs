// lib/features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart
// 🔄 REFACTORIZADO - Imports corregidos para evitar ambiguedad

import '../../../../core/ai/models/ai_request_model.dart';
import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/ai/models/ai_context_builder.dart'; // ✅ Solo este import
import '../../../../core/ai/repositories/ai_repository.dart';
import '../../../habits/domain/repositories/habit_repository.dart';
import '../../domain/entities/educational_content.dart';
import '../../domain/entities/app_guide.dart';
import '../../domain/repositories/ai_assistant_repository.dart';
import '../datasources/offline_content_datasource.dart';

class AIAssistantRepositoryImpl implements AIAssistantRepository {
  final OfflineContentDatasource offlineContentDatasource;
  final AIRepository aiRepository; // ✅ Usar AI Repository centralizado
  final HabitRepository habitRepository;

  AIAssistantRepositoryImpl({
    required this.offlineContentDatasource,
    required this.aiRepository,
    required this.habitRepository,
  });

  // 📚 EDUCATIONAL CONTENT - Solo lógica específica de la feature
  @override
  Future<List<EducationalContent>> getEducationalContent() async {
    return await offlineContentDatasource.getEducationalContent();
  }

  @override
  Future<List<EducationalContent>> getOfflineEducationalContent() async {
    return await offlineContentDatasource.getEducationalContent();
  }

  // 📖 APP GUIDES - Solo lógica específica de la feature
  @override
  Future<List<AppGuide>> getAppGuides() async {
    return await offlineContentDatasource.getAppGuides();
  }

  // 🤖 AI RECOMMENDATIONS - Delegar completamente al core/ai/
  @override
  Future<AIResponse> getAIRecommendation() async {
    try {
      // 1. Generar contexto usando datos de hábitos
      final userContext = await _generateUserContext();
      
      // 2. Crear contexto con AIContextBuilder del core
      final aiContext = AIContextBuilder.buildPersonalRecommendationContext(
        habitNames: userContext['habit_names'] ?? [],
        completionRates: Map<String, double>.from(userContext['completion_rates'] ?? {}),
        currentStreak: userContext['current_streak'] ?? 0,
        longestStreak: userContext['longest_streak'] ?? 0,
        strugglingHabits: List<String>.from(userContext['struggling_habits'] ?? []),
        totalDaysTracked: userContext['total_days_tracked'] ?? 0,
        lastActiveDate: DateTime.parse(userContext['last_active_date'] ?? DateTime.now().toIso8601String()),
      );

      // 3. Crear request usando tipos del core
      final request = AIRequest(
        type: AIRequestType.personalRecommendation,
        prompt: _buildPersonalRecommendationPrompt(userContext),
        metadata: aiContext,
      );

      // 4. Delegar completamente al AIRepository centralizado
      return await aiRepository.generateResponse(request);
    } catch (e) {
      // Si falla, el aiRepository manejará el fallback automáticamente
      rethrow;
    }
  }

  // 🌐 CONNECTIVITY - Delegar al core/ai/
  @override
  Future<bool> hasInternetConnection() async {
    return await aiRepository.hasInternetConnection();
  }

  // 🔧 HELPERS PRIVADOS - Solo generar contexto, no lógica de IA

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

      // Obtener entradas de los últimos 30 días
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final entries = await habitRepository.getHabitEntriesForDateRange(startDate, now);

      // Calcular métricas básicas
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
  }

  String _buildPersonalRecommendationPrompt(Map<String, dynamic> context) {
    final habitNames = List<String>.from(context['habit_names'] ?? []);
    final completionRates = Map<String, double>.from(context['completion_rates'] ?? {});
    final currentStreak = context['current_streak'] ?? 0;
    final strugglingHabits = List<String>.from(context['struggling_habits'] ?? []);
    
    final avgCompletionRate = completionRates.values.isNotEmpty 
        ? completionRates.values.reduce((a, b) => a + b) / completionRates.values.length
        : 0.0;

    return '''
Eres un experto coach de hábitos que ayuda a usuarios de una app llamada Habitiurs.

DATOS DEL USUARIO:
${habitNames.isNotEmpty ? 'Hábitos actuales: ${habitNames.join(', ')}' : 'No tiene hábitos registrados aún'}
Tasa de cumplimiento: ${(avgCompletionRate * 100).toStringAsFixed(1)}%
Racha actual: $currentStreak días
${strugglingHabits.isNotEmpty ? 'Hábitos con dificultades: ${strugglingHabits.join(', ')}' : ''}

INSTRUCCIONES:
- Analiza sus datos y da un consejo personalizado y motivador
- Máximo 2 párrafos cortos
- Enfócate en mejoras pequeñas e incrementales
- Mantén un tono positivo pero realista

Genera tu recomendación:
''';
  }

  // Métodos de cálculo existentes (mantener sin cambios)
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