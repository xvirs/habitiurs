import '../../../../core/errors/failures.dart';
import '../entities/statistics.dart';
import '../repositories/statistics_repository.dart';

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
