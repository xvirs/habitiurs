import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/statistics/presentation/widgets/yearly_statistics_list.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';
import '../widgets/current_month_summary.dart';
import '../widgets/historical_chart.dart';
import '../../../../shared/widgets/skeleton.dart';

// FIXED: Convertir StatisticsPage a StatefulWidget para gestionar initState/dispose
// si necesita _today o AutomaticKeepAliveClientMixin, aunque para StatisticsPage
// usualmente no es necesario si no tiene estado local que mantener.
// Si no hay estado local, StatelessWidget es preferible.
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar estadísticas',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<StatisticsBloc>().add(LoadStatistics());
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is StatisticsLoaded) {
          return RefreshIndicator(
            onRefresh: () => _refreshStatistics(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // En refresco no se vacían las tarjetas: se mantiene la
                        // data y el pull-to-refresh da el feedback (isRefreshing
                        // false para no mostrar spinners por sección).
                        CurrentMonthSummary(
                          statistics: state.currentMonth,
                          isRefreshing: false,
                        ),
                        YearlyStatisticsList(
                          statistics: state.currentYear,
                          isRefreshing: false,
                        ),
                        HistoricalChart(
                          data: state.historicalData,
                          isRefreshing: false,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
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

/// Skeleton de la primera carga de estadísticas: tres tarjetas con la forma de
/// las secciones (mes, año, histórico).
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
            _card(context, 180),
            const SizedBox(height: 16),
            _card(context, 160),
            const SizedBox(height: 16),
            _card(context, 140),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, double height) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 160, height: 22),
          const SizedBox(height: 16),
          Skeleton(height: height, radius: 12),
        ],
      ),
    );
  }
}
