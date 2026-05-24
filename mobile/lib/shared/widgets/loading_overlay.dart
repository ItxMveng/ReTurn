import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Overlay de chargement — à utiliser avec Stack ou showDialog
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});
  final String? message;

  static Future<T> show<T>(BuildContext context, Future<T> future, {String? message}) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (_) => LoadingOverlay(message: message),
    ).then((_) => future);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
              if (message != null) ...
                [
                  const SizedBox(height: 16),
                  Text(message!, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
