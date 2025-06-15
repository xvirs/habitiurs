// lib/features/statistics/domain/usecases/get_current_month_statistics.dart
import '../../../../core/errors/failures.dart';
import '../entities/statistics.dart';
import '../repositories/statistics_repository.dart';

class GetCurrentMonthStatistics {
  final StatisticsRepository repository;

  GetCurrentMonthStatistics(this.repository);

  Future<MonthlyStatistics> call() async {
    try {
      return await repository.getCurrentMonthStatistics();
    } catch (e) {
      throw DatabaseFailure('Error al obtener estadísticas del mes actual');
    }
  }
}

// lib/features/statistics/domain/usecases/get_current_year_statistics.dart
class GetCurrentYearStatistics {
  final StatisticsRepository repository;

  GetCurrentYearStatistics(this.repository);

  Future<List<MonthlyStatistics>> call() async {
    try {
      return await repository.getCurrentYearStatistics();
    } catch (e) {
      throw DatabaseFailure('Error al obtener estadísticas del año actual');
    }
  }
}

// lib/features/statistics/domain/usecases/get_historical_data.dart
class GetHistoricalData {
  final StatisticsRepository repository;

  GetHistoricalData(this.repository);

  Future<List<HistoricalDataPoint>> call() async {
    try {
      return await repository.getHistoricalData();
    } catch (e) {
      throw DatabaseFailure('Error al obtener datos históricos');
    }
  }
}