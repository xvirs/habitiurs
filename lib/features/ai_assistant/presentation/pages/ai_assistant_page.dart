// lib/features/ai_assistant/presentation/pages/ai_assistant_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
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
    return BlocProvider(
      create: (context) => InjectionContainer().aiAssistantBloc..add(LoadAIAssistantData()),
      child: const AIAssistantContent(),
    );
  }
}

class AIAssistantContent extends StatelessWidget {
  const AIAssistantContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIAssistantBloc, AIAssistantState>(
      builder: (context, state) {
        if (state is AIAssistantLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AIAssistantError) {
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
                  state.message,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<AIAssistantBloc>().add(LoadAIAssistantData());
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is AIAssistantLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AIAssistantBloc>().add(LoadAIAssistantData());
            },
            // ✅ MODIFICADO: REMOVED SafeArea(top: true)
            child: SingleChildScrollView( // Directly return SingleChildScrollView
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  AIRecommendationSection(
                    recommendation: state.currentRecommendation,
                    isLoading: state.isRecommendationLoading,
                    hasInternetConnection: state.hasInternetConnection,
                    onRefresh: () {
                      context.read<AIAssistantBloc>().add(RefreshAIRecommendation());
                    },
                  ),
                  EducationalContentSection(content: state.educationalContent),
                  AppGuideSection(guides: state.appGuides),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }

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
      },
    );
  }
}

