import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../matches/application/matches_notifier.dart';

/// Liste des conversations (une par match confirmé)
class MessagingListPage extends ConsumerWidget {
  const MessagingListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesState = ref.watch(matchesNotifierProvider);
    final activeMatches = [
      ...matchesState.confirmed,
      ...matchesState.completed,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messagerie'),
        backgroundColor: AppColors.background,
      ),
      body: matchesState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeMatches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.onSurfaceVariant.withOpacity(0.3)),
                      const SizedBox(height: 12),
                      const Text('Aucune conversation active',
                        style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      const Text('Les conversations apparaissent quand un match est confirmé',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeMatches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final match = activeMatches[i];
                    final docType = match.declarationFound?.documentLabel ?? '?';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: const Icon(Icons.compare_arrows_rounded, color: AppColors.primary, size: 20),
                      ),
                      title: Text(docType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        match.isCompleted ? 'Restitution terminée' : 'Match confirmé — Planifier la remise',
                        style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      trailing: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: match.isCompleted ? AppColors.success : AppColors.primary,
                        ),
                      ),
                      onTap: () => context.pushNamed(
                        RouteNames.conversation,
                        pathParameters: {'matchId': match.id},
                      ),
                    );
                  },
                ),
    );
  }
}
