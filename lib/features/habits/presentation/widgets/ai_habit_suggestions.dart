// lib/features/habits/presentation/widgets/ai_habit_suggestions.dart
import 'package:flutter/material.dart';
import 'package:habitiurs/core/ai/models/ai_context_builder.dart';
import '../../../../core/di/injection_container.dart';

class AIHabitSuggestions extends StatefulWidget {
  final List<String> currentHabits;
  final Map<String, double> completionRates;

  const AIHabitSuggestions({
    super.key,
    required this.currentHabits,
    required this.completionRates,
  });

  @override
  State<AIHabitSuggestions> createState() => _AIHabitSuggestionsState();
}

class _AIHabitSuggestionsState extends State<AIHabitSuggestions> {
  bool _isLoading = false;
  String? _suggestion;
  String? _error;
  
  // Cache para evitar requests duplicados
  String? _lastRequestHash;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              onRefresh: _isLoading ? null : _getAISuggestions,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 12),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _LoadingState();
    } else if (_error != null) {
      return _ErrorState(
        error: _error!,
        onRetry: _getAISuggestions,
      );
    } else if (_suggestion != null) {
      return _SuggestionState(suggestion: _suggestion!);
    } else {
      return const _InitialState();
    }
  }

  Future<void> _getAISuggestions() async {
    final requestHash = _generateRequestHash();
    
    // Evitar requests duplicados
    if (requestHash == _lastRequestHash && _suggestion != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aiRepository = InjectionContainer().aiRepository;
      
      final context = AIContextBuilder.buildHabitAnalysisContext(
        habitNames: widget.currentHabits,
        completionRates: widget.completionRates,
        currentStreak: _calculateCurrentStreak(),
        strugglingHabits: _identifyStrugglingHabits(),
      );

      final response = await aiRepository.analyzeHabitPatterns(context);
      
      if (mounted) {
        setState(() {
          _suggestion = response.content;
          _isLoading = false;
          _lastRequestHash = requestHash;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron obtener sugerencias en este momento';
          _isLoading = false;
        });
      }
    }
  }

  String _generateRequestHash() {
    return '${widget.currentHabits.join('|')}_${widget.completionRates.toString()}';
  }

  int _calculateCurrentStreak() {
    // Implementación simplificada - en producción usar datos reales
    return 5;
  }

  List<String> _identifyStrugglingHabits() {
    return widget.completionRates.entries
        .where((entry) => entry.value < 0.6)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Header con título y botón de refresh
class _Header extends StatelessWidget {
  final VoidCallback? onRefresh;
  final bool isLoading;

  const _Header({
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
          icon: AnimatedRotation(
            turns: isLoading ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: const Icon(Icons.refresh),
          ),
          onPressed: onRefresh,
          tooltip: 'Obtener nuevas sugerencias',
        ),
      ],
    );
  }
}

/// Estado de carga
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text('Analizando tus hábitos...'),
        ],
      ),
    );
  }
}

/// Estado de error
class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado con sugerencia
class _SuggestionState extends StatelessWidget {
  final String suggestion;

  const _SuggestionState({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            suggestion,
            style: TextStyle(
              color: Colors.blue[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado inicial
class _InitialState extends StatelessWidget {
  const _InitialState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined, 
            size: 48, 
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón de actualizar para obtener sugerencias personalizadas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}