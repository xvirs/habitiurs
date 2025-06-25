import 'package:flutter/material.dart';
import 'package:habitiurs/core/ai/models/ai_context_builder.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/statistics.dart';

class AIStatisticsInsights extends StatefulWidget {
  final MonthlyStatistics currentMonth;
  final List<MonthlyStatistics> yearlyStats;
  final List<HistoricalDataPoint> historicalData;

  const AIStatisticsInsights({
    super.key,
    required this.currentMonth,
    required this.yearlyStats,
    required this.historicalData,
  });

  @override
  State<AIStatisticsInsights> createState() => _AIStatisticsInsightsState();
}

class _AIStatisticsInsightsState extends State<AIStatisticsInsights> {
  bool _isLoadingTrends = false;
  bool _isLoadingPrediction = false;
  String? _trendsInsight;
  String? _predictionInsight;
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
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildInsightSection(
              title: 'Análisis de Tendencias',
              icon: Icons.trending_up,
              content: _trendsInsight,
              isLoading: _isLoadingTrends,
              onRefresh: _analyzeTrends,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildInsightSection(
              title: 'Predicción de Éxito',
              icon: Icons.psychology,
              content: _predictionInsight,
              isLoading: _isLoadingPrediction,
              onRefresh: _predictSuccess,
              color: Colors.blue,
            ),
            if (_error != null) _buildErrorDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Insights de IA',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightSection({
    required String title,
    required IconData icon,
    required String? content,
    required bool isLoading,
    required VoidCallback onRefresh,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color[600], size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color[700],
                    fontSize: 13,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, size: 18),
                onPressed: isLoading ? null : onRefresh,
                color: color[600],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            _buildLoadingIndicator(color)
          else if (content != null)
            Text(
              content,
              style: TextStyle(
                color: color[700],
                fontSize: 12,
                height: 1.4,
              ),
            )
          else
            _buildInitialMessage(color),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(MaterialColor color) {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color[600]!),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Analizando...',
            style: TextStyle(
              fontSize: 11,
              color: color[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialMessage(MaterialColor color) {
    return Text(
      'Toca actualizar para obtener insights',
      style: TextStyle(
        color: color[500],
        fontSize: 11,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildErrorDisplay() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _analyzeTrends() async {
    setState(() {
      _isLoadingTrends = true;
      _error = null;
    });
    try {
      final aiRepository = InjectionContainer().aiRepository;
      final context = AIContextBuilder.buildStatsAnalysisContext(
        monthlyCompletionRate: widget.currentMonth.completionRate,
        weeklyRates: widget.currentMonth.weeks.map((w) => w.completionRate).toList(),
        totalDaysTracked: _calculateTotalDaysTracked(),
        habitPerformance: _calculateHabitPerformance(),
      );
      final response = await aiRepository.analyzeStatisticsTrends(context);
      if (mounted) {
        setState(() {
          _trendsInsight = response.content;
          _isLoadingTrends = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error analizando tendencias';
          _isLoadingTrends = false;
        });
      }
    }
  }

  Future<void> _predictSuccess() async {
    setState(() {
      _isLoadingPrediction = true;
      _error = null;
    });
    try {
      final aiRepository = InjectionContainer().aiRepository;
      final context = AIContextBuilder.buildPredictionContext(
        historicalData: widget.historicalData.map((point) => {
          'date': point.date.toIso8601String(),
          'completion_rate': point.completionRate,
          'completed_count': point.completedCount,
          'skipped_count': point.skippedCount,
        }).toList(),
        currentHabits: _getCurrentHabitNames(),
        currentTrend: _calculateCurrentTrend(),
      );
      final response = await aiRepository.predictHabitSuccess(context);
      if (mounted) {
        setState(() {
          _predictionInsight = response.content;
          _isLoadingPrediction = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error generando predicción';
          _isLoadingPrediction = false;
        });
      }
    }
  }

  int _calculateTotalDaysTracked() {
    if (widget.historicalData.isEmpty) return 0;
    // Suma los completedCount y skippedCount de todos los puntos históricos
    return widget.historicalData.fold(0, (sum, point) => sum + point.completedCount + point.skippedCount);
  }

  Map<String, double> _calculateHabitPerformance() {
    // Para una implementación completa, esto debería venir de un cálculo más detallado
    // que involucre todos los hábitos individuales y sus tasas de cumplimiento.
    // Por ahora, se usa la tasa de cumplimiento del mes actual como un indicador general.
    return {
      'overall': widget.currentMonth.completionRate,
    };
  }

  double _calculateCurrentTrend() {
    if (widget.historicalData.length < 2) return 0.0;
    final recent = widget.historicalData.last.completionRate;
    final previous = widget.historicalData[widget.historicalData.length - 2].completionRate;
    return recent - previous;
  }

  List<String> _getCurrentHabitNames() {
    // Esto es un placeholder. En una aplicación real, obtendrías los nombres de los
    // hábitos activos del repositorio de hábitos.
    return ['Hábito de ejemplo 1', 'Hábito de ejemplo 2'];
  }
}