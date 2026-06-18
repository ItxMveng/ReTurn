import 'package:flutter/material.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/theme/app_colors.dart';

/// Widget d'erreur réutilisable avec action de retry
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ex = mapException(error);
    final isRetryable = ex is NetworkException && onRetry != null;

    if (compact) {
      return Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(ex.message, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
          if (isRetryable)
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconForException(ex),
              size: 56,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _titleForException(ex),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ex.message,
              style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (isRetryable) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForException(AppException ex) => switch (ex) {
    NetworkException() => Icons.wifi_off_rounded,
    UnauthorizedException() => Icons.lock_outline_rounded,
    NotFoundException() => Icons.search_off_rounded,
    ServerException() => Icons.cloud_off_rounded,
    _ => Icons.error_outline_rounded,
  };

  String _titleForException(AppException ex) => switch (ex) {
    NetworkException() => 'Pas de connexion',
    UnauthorizedException() => 'Session expirée',
    NotFoundException() => 'Introuvable',
    ServerException() => 'Erreur serveur',
    _ => 'Une erreur est survenue',
  };
}
