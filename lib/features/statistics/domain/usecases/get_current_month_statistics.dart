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
