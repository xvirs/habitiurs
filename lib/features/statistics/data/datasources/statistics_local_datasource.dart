import '../../../../core/database/database_helper.dart';
import '../../../../shared/enums/habit_status.dart';
import '../models/statistics_model.dart';

abstract class StatisticsLocalDatasource {
  Future<MonthlyStatisticsModel> getCurrentMonthStatistics();
  Future<List<MonthlyStatisticsModel>> getCurrentYearStatistics();
  Future<List<HistoricalDataPointModel>> getHistoricalData();
  Future<MonthlyStatisticsModel> getMonthStatistics(int year, int month);
}

class StatisticsLocalDatasourceImpl implements StatisticsLocalDatasource {
  final DatabaseHelper databaseHelper;

  StatisticsLocalDatasourceImpl({required this.databaseHelper});

  @override
  Future<MonthlyStatisticsModel> getCurrentMonthStatistics() async {
    final now = DateTime.now();
    print('📊 [Statistics] Cargando estadísticas mes ${now.month}/${now.year}');
    return await getMonthStatistics(now.year, now.month);
  }

  @override
  Future<List<MonthlyStatisticsModel>> getCurrentYearStatistics() async {
    final now = DateTime.now();
    print('📊 [Statistics] Cargando estadísticas del año ${now.year}');
    final List<MonthlyStatisticsModel> yearStatistics = [];
    for (int month = 1; month <= 12; month++) {
      final monthStats = await getMonthStatistics(now.year, month);
      if (monthStats.totalHabits > 0) {
        yearStatistics.add(monthStats);
      }
    }
    print('📊 [Statistics] Año ${now.year}: ${yearStatistics.length} mes(es) con datos');
    return yearStatistics;
  }

  @override
  Future<List<HistoricalDataPointModel>> getHistoricalData() async {
    print('📊 [Statistics] Cargando datos históricos...');
    final db = await databaseHelper.database;
    const query = '''
      SELECT
        strftime('%Y-%m', date) as date,
        COUNT(CASE WHEN status = ? THEN 1 END) as completed_count,
        COUNT(CASE WHEN status = ? THEN 1 END) as skipped_count
      FROM habit_entries
      WHERE status IN (?, ?)
      GROUP BY strftime('%Y-%m', date)
      ORDER BY date ASC
    ''';
    final result = await db.rawQuery(query, [
      HabitStatus.completed.index,
      HabitStatus.skipped.index,
      HabitStatus.completed.index,
      HabitStatus.skipped.index,
    ]);
    print('📊 [Statistics] ${result.length} punto(s) histórico(s) obtenidos');
    return result.map((map) {
      final dateStr = map['date'] as String;
      final parts = dateStr.split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);

      return HistoricalDataPointModel.fromMap({
        'date': date.toIso8601String(),
        'completed_count': map['completed_count'],
        'skipped_count': map['skipped_count'],
      });
    }).toList();
  }

  @override
  Future<MonthlyStatisticsModel> getMonthStatistics(int year, int month) async {
    final db = await databaseHelper.database;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final now = DateTime.now();

    // 1. Obtener "Total Esperado" (Opportunities) calculado teóricamente
    // Basado en cuándo se creó cada hábito.
    final habitsResult = await db.query('habits');
    int calculatedTotalHabits = 0;

    // Límite superior para contar "oportunidades": Hasta hoy o fin de mes, lo que pase antes.
    // No contamos días futuros como "pendientes/omitidos" en las estadísticas.
    DateTime calculationEnd = lastDay;
    if (now.isBefore(lastDay)) {
      calculationEnd = DateTime(now.year, now.month, now.day);
    }

    for (var habitMap in habitsResult) {
      final createdAtStr =
          habitMap['created_at'] as String; // FIXED: Use raw DB column name
      final createdAt = DateTime.parse(createdAtStr);

      // Calcular intersección de rangos:
      // [createdAt, calculationEnd] INTERSECT [firstDay, lastDay]

      // Start: Mayor entre (Inicio Mes, Creación Hábito)
      DateTime effectiveStart =
          firstDay.isAfter(createdAt) ? firstDay : createdAt;

      // Ajustar start al inicio del día para conteo correcto
      effectiveStart = DateTime(
        effectiveStart.year,
        effectiveStart.month,
        effectiveStart.day,
      );

      if (effectiveStart.isAfter(calculationEnd)) {
        continue;
      }

      // Días de diferencia + 1 (inclusivo)
      final days = calculationEnd.difference(effectiveStart).inDays + 1;
      if (days > 0) {
        calculatedTotalHabits += days;
      }
    }

    // 2. Obtener conteos reales de la BD (solo Completed importa mucho ahora)
    const monthQuery = '''
      SELECT 
        COUNT(CASE WHEN status = ? THEN 1 END) as completed_count,
        COUNT(CASE WHEN status = ? THEN 1 END) as explicit_skipped_count
      FROM habit_entries
      WHERE date >= ? AND date <= ?
    ''';

    final monthResult = await db.rawQuery(monthQuery, [
      HabitStatus.completed.index,
      HabitStatus.skipped.index,
      firstDay.toIso8601String().split('T')[0],
      lastDay.toIso8601String().split('T')[0],
    ]);

    final monthData = monthResult.first;
    final completedCount = monthData['completed_count'] as int;

    // Skipped REAL = (Oportunidades Totales - Completados).
    // Esto asume que todo lo no completado en el pasado es "skipped" (explícito o implícito).
    // Nota: calculatedTotalHabits ya está acotado a "hoy", así que no cuenta futuro.
    int skippedCount = calculatedTotalHabits - completedCount;
    if (skippedCount < 0) skippedCount = 0; // Protección

    final weeks = await _getWeeklyStatistics(
      year,
      month,
      firstDay,
      lastDay,
      habitsResult,
    );

    return MonthlyStatisticsModel(
      year: year,
      month: month,
      totalHabits: calculatedTotalHabits,
      completedCount: completedCount,
      skippedCount: skippedCount,
      pendingCount:
          0, // En estadísticas pasadas, pending no tiene sentido, es skipped.
      weeks: weeks,
    );
  }

  Future<List<WeeklyStatisticsModel>> _getWeeklyStatistics(
    int year,
    int month,
    DateTime firstDay,
    DateTime lastDay,
    List<Map<String, Object?>> allHabits,
  ) async {
    final db = await databaseHelper.database;
    final List<WeeklyStatisticsModel> weeks = [];
    final now = DateTime.now();

    DateTime currentWeekStart = firstDay;
    int weekNumber = 1;

    // Iteramos hasta cubrir todo el mes
    while (currentWeekStart.isBefore(lastDay) ||
        currentWeekStart.isAtSameMomentAs(lastDay)) {
      // Encontrar el final de la semana (Domingo) o fin de mes
      int daysToSunday = 7 - currentWeekStart.weekday;
      DateTime currentWeekEnd = currentWeekStart.add(
        Duration(days: daysToSunday),
      );

      if (currentWeekEnd.isAfter(lastDay)) {
        currentWeekEnd = lastDay;
      }

      // Límite de cálculo temporal (no futuro) para conteo de "duties"
      DateTime calculationDutyEnd = currentWeekEnd;
      if (now.isBefore(currentWeekEnd)) {
        calculationDutyEnd = DateTime(now.year, now.month, now.day);
      }

      // 1. Calcular Total Esperado para esta semana
      int calculatedWeekTotal = 0;

      if (!currentWeekStart.isAfter(now)) {
        for (var habitMap in allHabits) {
          final createdAtStr =
              habitMap['created_at'] as String; // FIXED: column name
          final createdAt = DateTime.parse(createdAtStr);

          // Start effective: Mayor entre (Inicio Semana, Creación Hábito)
          DateTime effectiveStart =
              currentWeekStart.isAfter(createdAt)
                  ? currentWeekStart
                  : createdAt;
          effectiveStart = DateTime(
            effectiveStart.year,
            effectiveStart.month,
            effectiveStart.day,
          );

          if (effectiveStart.isAfter(calculationDutyEnd)) continue;

          final days = calculationDutyEnd.difference(effectiveStart).inDays + 1;

          if (days > 0) {
            calculatedWeekTotal += days;
          }
        }
      }

      const weekQuery = '''
      SELECT 
        COUNT(CASE WHEN status = ? THEN 1 END) as completed_count
      FROM habit_entries
      WHERE date >= ? AND date <= ?
    ''';

      final weekResult = await db.rawQuery(weekQuery, [
        HabitStatus.completed.index,
        currentWeekStart.toIso8601String().split('T')[0],
        currentWeekEnd.toIso8601String().split('T')[0],
      ]);
      final weekData = weekResult.first;
      final completedCount = weekData['completed_count'] as int;

      int skippedCount = calculatedWeekTotal - completedCount;
      if (skippedCount < 0) skippedCount = 0;

      weeks.add(
        WeeklyStatisticsModel(
          weekNumber: weekNumber,
          startDate: currentWeekStart,
          endDate: currentWeekEnd,
          completedCount: completedCount,
          skippedCount: skippedCount,
          pendingCount: 0,
        ),
      );

      currentWeekStart = currentWeekEnd.add(const Duration(days: 1));
      weekNumber++;
    }
    return weeks;
  }
}
