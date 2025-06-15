// lib/features/statistics/domain/repositories/statistics_repository.dart
import '../entities/statistics.dart';

abstract class StatisticsRepository {
  /// Obtiene las estadísticas del mes actual
  Future<MonthlyStatistics> getCurrentMonthStatistics();
  
  /// Obtiene las estadísticas de todos los meses del año actual
  Future<List<MonthlyStatistics>> getCurrentYearStatistics();
  
  /// Obtiene los datos históricos para el gráfico
  /// Retorna puntos de datos mensuales desde el primer registro
  Future<List<HistoricalDataPoint>> getHistoricalData();
  
  /// Obtiene estadísticas de un mes específico
  Future<MonthlyStatistics> getMonthStatistics(int year, int month);
}