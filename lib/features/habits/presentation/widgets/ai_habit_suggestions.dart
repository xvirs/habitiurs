// lib/features/habits/presentation/widgets/ai_habit_suggestions.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/core/ai/models/ai_context_builder.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/ai/models/ai_request_model.dart';

class AIHabitSuggestions extends StatefulWidget {
  final List<String> currentHabits;
  final Map<String, double> completionRates;

  const AIHabitSuggestions({
    Key? key,
    required this.currentHabits,
    required this.completionRates,
  }) : super(key: key);

  @override
  State<AIHabitSuggestions> createState() => _AIHabitSuggestionsState();
}

class _AIHabitSuggestionsState extends State<AIHabitSuggestions> {
  bool _isLoading = false;
  String? _suggestion;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sugerencias de IA',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _getAISuggestions,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Analizando tus hábitos...'),
                  ],
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              )
            else if (_suggestion != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Recomendación personalizada',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _suggestion!,
                      style: TextStyle(
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(Icons.psychology_outlined, 
                         size: 48, 
                         color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Toca el botón de actualizar para obtener sugerencias personalizadas',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getAISuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _suggestion = null;
    });

    try {
      final aiRepository = InjectionContainer().aiRepository;
      
      // Construir contexto específico para análisis de hábitos
      final context = AIContextBuilder.buildHabitAnalysisContext(
        habitNames: widget.currentHabits,
        completionRates: widget.completionRates,
        currentStreak: _calculateCurrentStreak(),
        strugglingHabits: _identifyStrugglingHabits(),
      );

      // Obtener sugerencia de IA
      final response = await aiRepository.analyzeHabitPatterns(context);
      
      setState(() {
        _suggestion = response.content;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = 'No se pudieron obtener sugerencias en este momento';
        _isLoading = false;
      });
    }
  }

  int _calculateCurrentStreak() {
    // Lógica simplificada - en la implementación real usarías datos del repository
    return 5; // Placeholder
  }

  List<String> _identifyStrugglingHabits() {
    return widget.completionRates.entries
        .where((entry) => entry.value < 0.6)
        .map((entry) => entry.key)
        .toList();
  }
}



