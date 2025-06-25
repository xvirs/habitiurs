// lib/features/statistics/presentation/pages/statistics_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/statistics/presentation/widgets/yearly_statistics_list.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';
import '../widgets/current_month_summary.dart';
import '../widgets/historical_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InjectionContainer().statisticsBloc..add(LoadStatistics()),
      child: const StatisticsContent(),
    );
  }
}

class StatisticsContent extends StatelessWidget {
  const StatisticsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        if (state is StatisticsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is StatisticsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
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
          return Expanded(
            // ✅ MODIFIED: Added top padding here
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0), // Add top padding
              child: RefreshIndicator(
                onRefresh: () async {
                  print('Pull-to-refresh activado en StatisticsPage');
                  context.read<StatisticsBloc>().add(RefreshStatistics());
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      child: CurrentMonthSummary(
                        statistics: state.currentMonth,
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      child: YearlyStatisticsList(
                        statistics: state.currentYear,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: HistoricalChart(data: state.historicalData),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Cargando estadísticas...',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}