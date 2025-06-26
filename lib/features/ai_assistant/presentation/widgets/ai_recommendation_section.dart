// lib/features/ai_assistant/presentation/widgets/ai_recommendation_section.dart
import 'package:flutter/material.dart';
import '../../../../core/ai/models/ai_response_model.dart';
import '../../../../core/ai/services/ai_fallback_service.dart'; // Importar el servicio de fallback

class AIRecommendationSection extends StatelessWidget {
  final AIResponse? recommendation;
  final bool isLoading;
  final bool hasInternetConnection;
  final VoidCallback onRefresh;

  const AIRecommendationSection({
    Key? key,
    this.recommendation,
    this.isLoading = false,
    this.hasInternetConnection = false,
    required this.onRefresh,
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
            Row(
              children: [
                Icon(
                  Icons.psychology_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Asistente IA Personalizado',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: isLoading ? null : onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildConnectionStatus(context),
            const SizedBox(height: 16),
            _buildRecommendationContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    return Row(
      children: [
        Icon(
          hasInternetConnection ? Icons.cloud_done : Icons.cloud_off,
          size: 16,
          color: hasInternetConnection ? Colors.green[600] : Colors.orange[600],
        ),
        const SizedBox(width: 4),
        Text(
          hasInternetConnection
              ? 'Conectado con Gemini AI'
              : 'Modo offline - Consejos locales',
          style: TextStyle(
            fontSize: 12,
            color: hasInternetConnection ? Colors.green[600] : Colors.orange[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationContent(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Generando recomendación personalizada...',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final AIResponse? displayedRecommendation = recommendation;

    if (displayedRecommendation == null || !displayedRecommendation.isFromAI) {
      // ✅ CORRECCIÓN: Acceder a la instancia singleton de AIFallbackService
      final fallbackContent = AIFallbackService().getPersonalRecommendationFallbackContent({});
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.orange[200]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: Colors.orange[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Consejo general (offline)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange[600],
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fallbackContent,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: displayedRecommendation.isFromAI
            ? Colors.blue[50]
            : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: displayedRecommendation.isFromAI
              ? Colors.blue[200]!
              : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                displayedRecommendation.isFromAI
                    ? Icons.auto_awesome
                    : Icons.lightbulb_outline,
                size: 16,
                color: displayedRecommendation.isFromAI
                  ? Colors.blue[600]
                    : Colors.orange[600],
              ),
              const SizedBox(width: 4),
              Text(
                displayedRecommendation.isFromAI
                    ? 'Recomendación de IA'
                    : 'Consejo general',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: displayedRecommendation.isFromAI
                      ? Colors.blue[600]
                      : Colors.orange[600],
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(displayedRecommendation.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            displayedRecommendation.content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
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