// lib/features/app/presentation/pages/app_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/bootstrap/app_bootstrap.dart';
import '../../../../core/bootstrap/app_state.dart';
import '../../../../shared/widgets/error_screen.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../auth/presentation/pages/auth_wrapper.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../habits/presentation/bloc/habit_bloc.dart';
import '../../../statistics/presentation/bloc/statistics_bloc.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';

class AppPage extends StatefulWidget {
  final AppState appState;

  const AppPage({
    Key? key,
    required this.appState,
  }) : super(key: key);

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  late AppState _appState;
  bool _isRetrying = false;
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState;
    OnboardingPage.isCompleted().then((done) {
      if (mounted) setState(() => _onboardingCompleted = done);
    });
  }

  Future<void> _retryInitialization() async {
    setState(() => _isRetrying = true);
    final newState = await AppBootstrap().initialize();
    if (!mounted) return;
    setState(() {
      _appState = newState;
      _isRetrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habitiurs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isRetrying || _onboardingCompleted == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_appState.hasError) {
      return ErrorScreen(
        error: _appState.error!,
        onRetry: _retryInitialization,
      );
    }

    if (_onboardingCompleted == false) {
      return OnboardingPage(
        onDone: () => setState(() => _onboardingCompleted = true),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => InjectionContainer().authBloc..add(AuthInitializationRequested()),
        ),
        BlocProvider<HabitBloc>(
          // Solo inicializa el Bloc; LoadHabits se dispara desde AuthBloc
          // cuando el usuario está autenticado.
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
