class MonthlyStatistics {
  final int year;
  final int month;
  final int totalHabits;
  final int completedCount;
  final int skippedCount;
  final int pendingCount;
  final List<WeeklyStatistics> weeks;

  const MonthlyStatistics({
    required this.year,
    required this.month,
    required this.totalHabits,
    required this.completedCount,
    required this.skippedCount,
    required this.pendingCount,
    required this.weeks,
  });

  double get completionRate =>
      totalHabits > 0 ? (completedCount / totalHabits) * 100 : 0.0;

  String get monthName {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    if (month < 1 || month > 12) {
      return 'Desconocido';
    }
    return months[month - 1];
  }
}

class WeeklyStatistics {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final int completedCount;
  final int skippedCount;
  final int pendingCount;

  const WeeklyStatistics({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.completedCount,
    required this.skippedCount,
    required this.pendingCount,
  });

  int get totalEntries => completedCount + skippedCount + pendingCount;

  double get completionRate =>
      totalEntries > 0 ? (completedCount / totalEntries) * 100 : 0.0;
}

class HistoricalDataPoint {
  final DateTime date;
  final int completedCount;
  final int skippedCount;
  final double completionRate;

  const HistoricalDataPoint({
    required this.date,
    required this.completedCount,
    required this.skippedCount,
    required this.completionRate,
  });
}

/// Actividad de UN día: cuántos hábitos se completaron y cuántos se saltearon.
/// Alimenta el mapa de constancia (heatmap tipo GitHub) y las rachas.
class DailyActivity {
  final DateTime date;
  final int completedCount;
  final int skippedCount;

  const DailyActivity({
    required this.date,
    required this.completedCount,
    required this.skippedCount,
  });

  int get totalEntries => completedCount + skippedCount;

  /// Proporción de hábitos completados ese día (0..1).
  double get ratio => totalEntries > 0 ? completedCount / totalEntries : 0.0;

  /// Nivel de intensidad para el heatmap: 0 = nada, 1..3 según ratio.
  int get level {
    if (completedCount == 0) return 0;
    if (ratio >= 0.8) return 3;
    if (ratio >= 0.4) return 2;
    return 1;
  }
}

/// Métricas derivadas de la actividad diaria: rachas, totales y patrón
/// por día de la semana. Un día "cuenta" para la racha si se completó AL
/// MENOS un hábito (decisión de producto: motivar, no exigir perfección).
class ActivityInsights {
  final int currentStreak;
  final int bestStreak;
  final int totalCompleted;

  /// 1=lunes … 7=domingo, o null si no hay datos suficientes (< 28 días).
  final int? bestWeekday;
  final int? worstWeekday;

  const ActivityInsights({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompleted,
    this.bestWeekday,
    this.worstWeekday,
  });

  factory ActivityInsights.fromDaily(List<DailyActivity> daily) {
    if (daily.isEmpty) {
      return const ActivityInsights(
        currentStreak: 0,
        bestStreak: 0,
        totalCompleted: 0,
      );
    }

    DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
    final byDay = <DateTime, DailyActivity>{
      for (final a in daily) dayKey(a.date): a,
    };

    final total = daily.fold<int>(0, (s, a) => s + a.completedCount);

    // Mejor racha: recorrer días ordenados y contar consecutivos con ≥1.
    final activeDays =
        byDay.entries
            .where((e) => e.value.completedCount > 0)
            .map((e) => e.key)
            .toList()
          ..sort();
    int best = 0;
    int run = 0;
    DateTime? prev;
    for (final d in activeDays) {
      run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }

    // Racha actual: consecutivos hacia atrás terminando hoy o ayer (hoy aún
    // no rompe la racha si todavía no marcaste nada).
    final today = dayKey(DateTime.now());
    int current = 0;
    var cursor =
        (byDay[today]?.completedCount ?? 0) > 0
            ? today
            : today.subtract(const Duration(days: 1));
    while ((byDay[cursor]?.completedCount ?? 0) > 0) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Patrón semanal: promedio de ratio por día de la semana. Pide al menos
    // 4 semanas de datos para no sacar conclusiones de 3 días.
    int? bestWd;
    int? worstWd;
    final span =
        activeDays.isEmpty
            ? 0
            : dayKey(
              daily.last.date,
            ).difference(dayKey(daily.first.date)).inDays;
    if (span >= 28) {
      final sums = List<double>.filled(8, 0);
      final counts = List<int>.filled(8, 0);
      for (final a in daily) {
        if (a.totalEntries == 0) continue;
        sums[a.date.weekday] += a.ratio;
        counts[a.date.weekday]++;
      }
      double bestAvg = -1;
      double worstAvg = 2;
      for (var wd = 1; wd <= 7; wd++) {
        if (counts[wd] < 2) continue;
        final avg = sums[wd] / counts[wd];
        if (avg > bestAvg) {
          bestAvg = avg;
          bestWd = wd;
        }
        if (avg < worstAvg) {
          worstAvg = avg;
          worstWd = wd;
        }
      }
      if (bestWd == worstWd) worstWd = null;
    }

    return ActivityInsights(
      currentStreak: current,
      bestStreak: best,
      totalCompleted: total,
      bestWeekday: bestWd,
      worstWeekday: worstWd,
    );
  }

  static const weekdayNames = [
    '',
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
}
