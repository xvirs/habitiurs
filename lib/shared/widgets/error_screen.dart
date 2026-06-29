// lib/shared/widgets/error_screen.dart - UI REUTILIZABLE
import 'package:flutter/material.dart';
import '../../core/errors/app_error.dart';

class ErrorScreen extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onOfflineMode;

  const ErrorScreen({
    Key? key,
    required this.error,
    this.onRetry,
    this.onOfflineMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getErrorIcon(), size: 64, color: _getErrorColor()),
              const SizedBox(height: 24),
              Text(
                error.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error.message,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _buildErrorDetails(context),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.permission:
        return Icons.security;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    switch (error.type) {
      case ErrorType.network:
        return Colors.orange[400]!;
      case ErrorType.authentication:
        return Colors.blue[400]!;
      default:
        return Colors.red[400]!;
    }
  }

  Widget _buildErrorDetails(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'Ver detalles técnicos',
        style: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getErrorColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getErrorColor().withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timestamp: ${error.timestamp}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.technicalDetails,
                style: TextStyle(
                  fontSize: 12,
                  color: _getErrorColor().withOpacity(0.8),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (onRetry != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ),

        if (onRetry != null && onOfflineMode != null)
          const SizedBox(height: 16),

        if (onOfflineMode != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onOfflineMode,
              child: const Text('Continuar en modo offline'),
            ),
          ),
      ],
    );
  }
}
