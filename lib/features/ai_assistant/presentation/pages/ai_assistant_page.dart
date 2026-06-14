// lib/features/ai_assistant/presentation/pages/ai_assistant_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../widgets/educational_content_section.dart';
import '../widgets/app_guide_section.dart';
import '../widgets/ai_recommendation_section.dart';

class AIAssistantPage extends StatelessWidget {
  const AIAssistantPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // FIXED: Removed local BlocProvider to use the global one from AppPage
    // This allows MainPage to access the same AIAssistantBloc instance
    return const _AIAssistantContent();
  }
}

class _AIAssistantContent extends StatelessWidget {
  const _AIAssistantContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIAssistantBloc, AIAssistantState>(
      builder: (context, state) {
        return switch (state) {
          AIAssistantLoading() => const _LoadingView(),
          AIAssistantError() => _ErrorView(
            message: state.message,
            onRetry:
                () =>
                    context.read<AIAssistantBloc>().add(LoadAIAssistantData()),
          ),
          AIAssistantLoaded() => _LoadedView(state: state),
          _ => const _InitialView(),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el asistente',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final AIAssistantLoaded state;

  const _LoadedView({required this.state});

  /// Pull-to-refresh: regenera la recomendación IA (acción manual,
  /// equivalente al botón de la topbar — cuesta una llamada a Gemini).
  Future<void> _refreshRecommendation(BuildContext context) async {
    final bloc = context.read<AIAssistantBloc>();
    bloc.add(RefreshAIRecommendation());
    await bloc.stream
        .firstWhere(
          (s) => s is! AIAssistantLoaded || !s.isRecommendationLoading,
        )
        .timeout(const Duration(seconds: 25), onTimeout: () => bloc.state);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refreshRecommendation(context),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            AIRecommendationSection(
              recommendation: state.currentRecommendation,
              isLoading: state.isRecommendationLoading,
              hasInternetConnection: state.hasInternetConnection,
            ),
            EducationalContentSection(content: state.educationalContent),
            AppGuideSection(guides: state.appGuides),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InitialView extends StatelessWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Cargando asistente...',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
