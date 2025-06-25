import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bootstrap/app_state.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/pages/auth_wrapper.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../habits/presentation/bloc/habit_bloc.dart';
import '../../../statistics/presentation/bloc/statistics_bloc.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';

class AppPage extends StatelessWidget {
  final AppState appState;

  const AppPage({
    Key? key,
    required this.appState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitiurs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (appState.hasError) {
      return ErrorScreen(
        error: appState.error!,
        onRetry: () {},
        onOfflineMode: () {},
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => InjectionContainer().authBloc..add(AuthInitializationRequested()),
        ),
        BlocProvider<HabitBloc>(
          create: (context) => InjectionContainer().habitBloc,
        ),
        BlocProvider<StatisticsBloc>(
          create: (context) => InjectionContainer().statisticsBloc,
        ),
        BlocProvider<AIAssistantBloc>(
          create: (context) => InjectionContainer().aiAssistantBloc,
        ),
      ],
      child: const AuthWrapper(),
    );
  }
}