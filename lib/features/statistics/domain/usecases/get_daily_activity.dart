import '../../../../core/errors/failures.dart';
import '../entities/statistics.dart';
import '../repositories/statistics_repository.dart';

class GetDailyActivity {
  final StatisticsRepository repository;

  GetDailyActivity(this.repository);

  Future<List<DailyActivity>> call() async {
    try {
      return await repository.getDailyActivity();
    } catch (e) {
      throw DatabaseFailure('Error al obtener la actividad diaria');
    }
  }
}
