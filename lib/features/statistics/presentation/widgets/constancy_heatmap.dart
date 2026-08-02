import 'package:flutter/material.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/statistics.dart';

/// Mapa de constancia tipo GitHub: columnas = semanas, filas = lun..dom.
/// La intensidad de verde refleja la proporción de hábitos completados ese
/// día. Los días flojos quedan neutros (sin rojo: se destaca el progreso,
/// no la falla). Tocar una celda muestra el detalle del día.
class ConstancyHeatmap extends StatelessWidget {
  final List<DailyActivity> daily;

  const ConstancyHeatmap({super.key, required this.daily});

  static DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = AppColors.completed(context);
    final byDay = <DateTime, DailyActivity>{
      for (final a in daily) _dayKey(a.date): a,
    };

    final today = _dayKey(DateTime.now());

    Color colorFor(int level) => switch (level) {
      3 => green,
      2 => green.withValues(alpha: 0.65),
      1 => green.withValues(alpha: 0.35),
      _ => theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 3.0;
        const labelWidth = 16.0;
        // Adaptativo: en pantallas anchas entran más semanas (hasta ~6 meses)
        // con celdas más grandes; en teléfono quedan ~15 (≈3,5 meses).
        final weeks = (((constraints.maxWidth - labelWidth) / 19).floor())
            .clamp(12, 26);
        final cell = ((constraints.maxWidth - labelWidth - gap * weeks) / weeks)
            .clamp(8.0, 22.0);

        // Lunes de la semana actual, y (weeks-1) semanas hacia atrás.
        final currentMonday = today.subtract(Duration(days: today.weekday - 1));
        final firstMonday = currentMonday.subtract(
          Duration(days: 7 * (weeks - 1)),
        );

        const monthNames = [
          '',
          'ene',
          'feb',
          'mar',
          'abr',
          'may',
          'jun',
          'jul',
          'ago',
          'sep',
          'oct',
          'nov',
          'dic',
        ];

        // Etiquetas de mes: sobre la primera semana cuyo lunes cambia de mes.
        final monthLabels = List<String>.filled(weeks, '');
        int? lastMonth;
        for (var w = 0; w < weeks; w++) {
          final monday = firstMonday.add(Duration(days: 7 * w));
          if (lastMonth != monday.month) {
            monthLabels[w] = monthNames[monday.month];
            lastMonth = monday.month;
          }
        }

        Widget dayLabel(String text) => SizedBox(
          width: labelWidth,
          height: cell + gap,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila de meses
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: labelWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var w = 0; w < weeks; w++)
                          SizedBox(
                            width: cell + gap,
                            child: Text(
                              monthLabels[w],
                              style: TextStyle(
                                fontSize: 8,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.visible,
                              softWrap: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Etiquetas de día (sparse, como GitHub)
                      Column(
                        children: [
                          dayLabel('L'),
                          dayLabel(''),
                          dayLabel('M'),
                          dayLabel(''),
                          dayLabel('V'),
                          dayLabel(''),
                          dayLabel('D'),
                        ],
                      ),
                      // Grilla
                      for (var w = 0; w < weeks; w++)
                        Padding(
                          padding: const EdgeInsets.only(right: gap),
                          child: Column(
                            children: [
                              for (var d = 0; d < 7; d++)
                                _Cell(
                                  date: firstMonday.add(
                                    Duration(days: 7 * w + d),
                                  ),
                                  activity:
                                      byDay[firstMonday.add(
                                        Duration(days: 7 * w + d),
                                      )],
                                  size: cell,
                                  gap: gap,
                                  color: colorFor(
                                    byDay[firstMonday.add(
                                              Duration(days: 7 * w + d),
                                            )]
                                            ?.level ??
                                        0,
                                  ),
                                  isFuture: firstMonday
                                      .add(Duration(days: 7 * w + d))
                                      .isAfter(today),
                                  isToday:
                                      firstMonday.add(
                                        Duration(days: 7 * w + d),
                                      ) ==
                                      today,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Leyenda
            Row(
              children: [
                Text(
                  'últimos ${(weeks / 4.33).round()} meses',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'Menos ',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                for (final lvl in [0, 1, 2, 3])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colorFor(lvl),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Text(
                  ' Más',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final DateTime date;
  final DailyActivity? activity;
  final double size;
  final double gap;
  final Color color;
  final bool isFuture;
  final bool isToday;

  const _Cell({
    required this.date,
    required this.activity,
    required this.size,
    required this.gap,
    required this.color,
    required this.isFuture,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isFuture) {
      // Días futuros: invisibles (la semana actual queda "recortada").
      return SizedBox(width: size, height: size + gap);
    }
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border:
                isToday
                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                    : null,
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    const months = [
      '',
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final label = '${date.day} ${months[date.month]}';
    final a = activity;
    final detail =
        (a == null || a.totalEntries == 0)
            ? 'sin registros'
            : '${a.completedCount} de ${a.totalEntries} hábitos completados';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label · $detail'),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}
