// lib/features/ai_assistant/presentation/widgets/ai_recommendation_section.dart
import 'package:flutter/material.dart';
import '../../../../core/ai/models/ai_response_model.dart';

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
            _Header(isLoading: isLoading),
            const SizedBox(height: 8),
            _ConnectionStatus(hasInternetConnection: hasInternetConnection),
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

class _Header extends StatelessWidget {
  final bool isLoading;

  const _Header({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.psychology_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Asistente IA Personalizado',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ConnectionStatus extends StatelessWidget {
  final bool hasInternetConnection;

  const _ConnectionStatus({required this.hasInternetConnection});

  @override
  Widget build(BuildContext context) {
    // Siempre mostrar como conectado ya que el fallback es inteligente
    return Row(
      children: [
        Icon(
          Icons.psychology,
          size: 16,
          color: Colors.blue[600],
        ),
        const SizedBox(width: 4),
        Text(
          'Recomendación IA Personalizada',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[600],
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'No se pudo obtener una recomendación en este momento. Intenta refrescar.',
        style: TextStyle(fontSize: 13),
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
    // Siempre usar estilo de IA para recomendaciones personalizadas
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RecommendationHeader(
            isFromAI: true, // Siempre mostrar como IA ya que es personalizado
            timestamp: recommendation.timestamp,
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.content,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _RecommendationHeader extends StatelessWidget {
  final bool isFromAI;
  final DateTime timestamp;

  const _RecommendationHeader({
    required this.isFromAI,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isFromAI ? Icons.auto_awesome : Icons.lightbulb_outline,
          size: 16,
          color: isFromAI ? Colors.blue[600] : Colors.orange[600],
        ),
        const SizedBox(width: 4),
        Text(
          isFromAI ? 'Recomendación de IA' : 'Consejo general',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isFromAI ? Colors.blue[600] : Colors.orange[600],
          ),
        ),
        const Spacer(),
        Text(
          _formatTime(timestamp),
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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
