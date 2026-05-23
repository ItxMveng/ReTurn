import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:docretour/features/matching/providers/match_provider.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;
  const NotificationBadge({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider).valueOrNull ?? 0;

    if (count == 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: GestureDetector(
            onTap: () async {
              try {
                await ref.read(matchRepositoryProvider).clearNotifications();
              } catch (_) {}
              ref.invalidate(notificationCountProvider);
              onTap?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
