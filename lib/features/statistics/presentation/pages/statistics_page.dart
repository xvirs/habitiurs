import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitiurs/features/statistics/presentation/widgets/yearly_statistics_list.dart';
import '../bloc/statistics_bloc.dart';
import '../bloc/statistics_event.dart';
import '../bloc/statistics_state.dart';
import '../widgets/current_month_summary.dart';
import '../widgets/historical_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, state) {
        print('📊 StatisticsPage - Estado actual: $state');
        if (state is StatisticsLoaded) {
          print('📊 StatisticsPage - currentMonth: ${state.currentMonth.monthName}');
          print('📊 StatisticsPage - currentYear count: ${state.currentYear.length}');
          print('📊 StatisticsPage - historicalData count: ${state.historicalData.length}');
        }

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
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<StatisticsBloc>().add(RefreshStatistics());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CurrentMonthSummary(statistics: state.currentMonth),
                    ),
                    YearlyStatisticsList(statistics: state.currentYear),
                    HistoricalChart(data: state.historicalData),
                    const SizedBox(height: 16),
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