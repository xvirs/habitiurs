// lib/features/statistics/presentation/widgets/stat_components.dart
// Componentes compartidos de la página de estadísticas, alineados con el
// lenguaje visual de las páginas de Hábitos y Asistente IA.
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Colores semánticos de estadísticas (mismos que la grilla semanal),
/// adaptados a tema claro/oscuro.
class StatColors {
  static Color completed(BuildContext context) => AppColors.completed(context);
  static Color skipped(BuildContext context) => AppColors.skipped(context);
  static Color pending(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
}

/// Barra fina segmentada: completados / no realizados / pendientes.
class StatSegmentedBar extends StatelessWidget {
  final int completed;
  final int skipped;
  final int pending;
  final double height;

  const StatSegmentedBar({
    super.key,
    required this.completed,
    required this.skipped,
    required this.pending,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final total = completed + skipped + pending;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: total == 0
            ? Container(color: StatColors.pending(context))
            : Row(
                children: [
                  if (completed > 0)
                    Expanded(
                      flex: completed,
                      child: Container(color: StatColors.completed(context)),
                    ),
                  if (skipped > 0)
                    Expanded(
                      flex: skipped,
                      child: Container(
                        color: StatColors.skipped(context)
                            .withValues(alpha: 0.85),
                      ),
                    ),
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: Container(color: StatColors.pending(context)),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Fila de estadística unificada: etiqueta + barra + valor.
/// Mismo estilo que las filas de "Hábitos de hoy" (blanca, borde fino).
class StatRow extends StatelessWidget {
  final String label;
  final int completed;
  final int skipped;
  final int pending;

  /// Texto del extremo derecho (ej. "3/28" o "11%"). Si es null se calcula
  /// el porcentaje de completados sobre el total.
  final String? trailing;

  const StatRow({
    super.key,
    required this.label,
    required this.completed,
    required this.skipped,
    required this.pending,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = completed + skipped + pending;
    final hasData = total > 0;
    final rate = hasData ? completed / total * 100 : 0.0;

    final trailingColor = !hasData
        ? theme.colorScheme.outline
        : rate >= 70
            ? StatColors.completed(context)
            : rate >= 40
                ? AppColors.warning(context)
                : StatColors.skipped(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatSegmentedBar(
              completed: completed,
              skipped: skipped,
              pending: pending,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              hasData ? (trailing ?? '${rate.toStringAsFixed(0)}%') : '—',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: trailingColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entrada de leyenda: punto de color (o línea, para series lineales).
class StatLegendEntry {
  final Color color;
  final String label;
  final bool isLine;

  const StatLegendEntry(this.color, this.label, {this.isLine = false});
}

/// Leyenda única por tarjeta (sustituye los chips repetidos por fila).
/// Sin [entries] muestra la leyenda estándar completados/no realizados/pendientes.
class StatLegend extends StatelessWidget {
  final List<StatLegendEntry>? entries;

  const StatLegend({super.key, this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = entries ??
        [
          StatLegendEntry(StatColors.completed(context), 'Completados'),
          StatLegendEntry(StatColors.skipped(context), 'No realizados'),
          StatLegendEntry(theme.colorScheme.outlineVariant, 'Pendientes'),
        ];

    Widget item(StatLegendEntry entry) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: entry.isLine ? 12 : 8,
            height: entry.isLine ? 2.5 : 8,
            decoration: BoxDecoration(
              color: entry.color,
              shape: entry.isLine ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: entry.isLine ? BorderRadius.circular(2) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            entry.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: items.map(item).toList(),
      ),
    );
  }
}
