import '../../../../core/errors/failures.dart';
import '../entities/statistics.dart';
import '../repositories/statistics_repository.dart';

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
