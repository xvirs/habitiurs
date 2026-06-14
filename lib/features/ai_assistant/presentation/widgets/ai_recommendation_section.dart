// lib/features/ai_assistant/presentation/widgets/ai_recommendation_section.dart
import 'package:flutter/material.dart';
import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../shared/widgets/section_header.dart';

class AIRecommendationSection extends StatelessWidget {
  final AIResponse? recommendation;
  final bool isLoading;
  final bool hasInternetConnection;

  const AIRecommendationSection({
    Key? key,
    this.recommendation,
    this.isLoading = false,
    this.hasInternetConnection = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              icon: Icons.psychology_outlined,
              title: 'Asistente IA',
            ),
            const SizedBox(height: 16),
            _RecommendationContent(
              recommendation: recommendation,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationContent extends StatelessWidget {
  final AIResponse? recommendation;
  final bool isLoading;

  const _RecommendationContent({
    required this.recommendation,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingContent();
    }

    if (recommendation == null) {
      return const _EmptyContent();
    }

    return _RecommendationCard(recommendation: recommendation!);
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              'Generando recomendación personalizada...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'No se pudo obtener una recomendación en este momento. Intenta refrescar.',
        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final AIResponse recommendation;

  const _RecommendationCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecommendationHeader(timestamp: recommendation.timestamp),
          const SizedBox(height: 10),
          Text(
            recommendation.content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _RecommendationHeader extends StatelessWidget {
  final DateTime timestamp;

  const _RecommendationHeader({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Text(
          'Recomendación de IA',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const Spacer(),
        Text(
          _formatTime(timestamp),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inHours < 1) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }
}
