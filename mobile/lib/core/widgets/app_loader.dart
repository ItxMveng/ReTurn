import 'package:flutter/material.dart';

/// Loader centré pour les états de chargement page entière
class AppLoader extends StatelessWidget {
  final String? message;
  const AppLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          if (message != null) ...[const SizedBox(height: 16), Text(message!, style: const TextStyle(fontSize: 14))],
        ],
      ),
    );
  }
}

/// Shimmer skeleton pour les listes en chargement
class SkeletonCard extends StatefulWidget {
  final double height;
  const SkeletonCard({super.key, this.height = 80});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.55), fontSize: 14), textAlign: TextAlign.center)],
            if (actionLabel != null && onAction != null) ...[const SizedBox(height: 24), ElevatedButton(onPressed: onAction, child: Text(actionLabel!))],
          ],
        ),
      ),
    );
  }
}
