import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../domain/entities/statistics.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';
import '../widgets/constancy_heatmap.dart';

/// Estadísticas rediseñadas: métricas héroe (rachas), mapa de constancia
/// tipo GitHub, tendencia mensual y patrón semanal. Sin rojo dominante:
/// se destaca el progreso, los días flojos quedan neutros.
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  /// Dispara el recálculo y espera a que el bloc termine, para que el
  /// indicador del gesto pull-to-refresh gire hasta que haya datos frescos.
  Future<void> _refreshStatistics(BuildContext context) async {
    final bloc = context.read<StatisticsBloc>();
    bloc.add(RefreshStatistics());
    await bloc.stream
        .firstWhere((s) => s is! StatisticsLoaded || !s.isRefreshing)
        .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        if (state is StatisticsLoading) {
          return const _StatisticsSkeleton();
        }

        if (state is StatisticsError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<StatisticsBloc>().add(LoadStatistics()),
          );
        }

        if (state is StatisticsLoaded) {
          final insights = state.insights;
          return RefreshIndicator(
            onRefresh: () => _refreshStatistics(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeroStats(
                      insights: insights,
                      monthRate: state.currentMonth.completionRate,
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      icon: Icons.calendar_view_month,
                      title: 'Mapa de constancia',
                      trailing: 'últimos 4 meses',
                      child: ConstancyHeatmap(daily: state.dailyActivity),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      icon: Icons.trending_up,
                      title: 'Tendencia mensual',
                      child: _MonthlyTrend(months: state.currentYear),
                    ),
                    if (insights.bestWeekday != null) ...[
                      const SizedBox(height: 12),
                      _WeekdayInsight(insights: insights),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        }

        return const _StatisticsSkeleton();
      },
    );
  }
}

// ─── Métricas héroe ─────────────────────────────────────────────────────────

class _HeroStats extends StatelessWidget {
  final ActivityInsights insights;
  final double monthRate;

  const _HeroStats({required this.insights, required this.monthRate});

  @override
  Widget build(BuildContext context) {
    final green = AppColors.completed(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Racha actual',
                value: '${insights.currentStreak}',
                suffix: insights.currentStreak == 1 ? 'día' : 'días',
                emoji: '🔥',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Mejor racha',
                value: '${insights.bestStreak}',
                suffix: insights.bestStreak == 1 ? 'día' : 'días',
                emoji: '🏆',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Este mes',
                value: '${monthRate.round()}%',
                valueColor: monthRate >= 50 ? green : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Completados',
                value: '${insights.totalCompleted}',
                suffix: 'en total',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String? emoji;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.suffix,
    this.emoji,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Text(
                  suffix!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de sección ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 17, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                Text(
                  trailing!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Tendencia mensual ──────────────────────────────────────────────────────

class _MonthlyTrend extends StatelessWidget {
  final List<MonthlyStatistics> months;

  const _MonthlyTrend({required this.months});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = AppColors.completed(context);

    if (months.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Todavía no hay meses con datos.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Últimos 6 meses con datos, en orden cronológico.
    final visible =
        months.length <= 6 ? months : months.sublist(months.length - 6);

    const maxBarHeight = 64.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final m in visible)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: (maxBarHeight * (m.completionRate / 100)).clamp(
                      3.0,
                      maxBarHeight,
                    ),
                    decoration: BoxDecoration(
                      // Intensidad según el logro, siempre en verde (sin rojo).
                      color:
                          m.completionRate >= 70
                              ? green
                              : m.completionRate >= 40
                              ? green.withValues(alpha: 0.65)
                              : green.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m.monthName.substring(0, 3),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${m.completionRate.round()}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          m.completionRate >= 50
                              ? green
                              : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Insight semanal ────────────────────────────────────────────────────────

class _WeekdayInsight extends StatelessWidget {
  final ActivityInsights insights;

  const _WeekdayInsight({required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = AppColors.completed(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_outlined, size: 18, color: green),
          const SizedBox(width: 6),
          Text(
            'Mejor día: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            ActivityInsights.weekdayNames[insights.bestWeekday!],
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (insights.worstWeekday != null) ...[
            Text(
              'Más difícil: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              ActivityInsights.weekdayNames[insights.worstWeekday!],
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Estados auxiliares ─────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error al cargar estadísticas',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Skeleton de la primera carga: métricas héroe + heatmap + tendencia.
class _StatisticsSkeleton extends StatelessWidget {
  const _StatisticsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: const [
                Expanded(child: Skeleton(height: 70, radius: 12)),
                SizedBox(width: 10),
                Expanded(child: Skeleton(height: 70, radius: 12)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(child: Skeleton(height: 70, radius: 12)),
                SizedBox(width: 10),
                Expanded(child: Skeleton(height: 70, radius: 12)),
              ],
            ),
            const SizedBox(height: 12),
            const Skeleton(height: 180, radius: 12),
            const SizedBox(height: 12),
            const Skeleton(height: 140, radius: 12),
          ],
        ),
      ),
    );
  }
}
