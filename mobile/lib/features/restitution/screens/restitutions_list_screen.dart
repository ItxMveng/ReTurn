import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/features/restitution/providers/restitution_provider.dart';
import 'package:docretour/shared/models/restitution.dart';

class RestitutionsListScreen extends ConsumerWidget {
  const RestitutionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(restitutionListProvider);
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Restitutions'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'En cours'),
              Tab(text: 'Terminées'),
            ],
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
            indicatorColor: cs.primary,
          ),
        ),
        body: asyncList.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(restitutionListProvider),
          ),
          data: (list) => TabBarView(
            children: [
              _RestitutionTab(
                items: list.where((r) => r.isActive).toList(),
                emptyLabel: 'Aucune restitution en cours',
              ),
              _RestitutionTab(
                items: list.where((r) => !r.isActive).toList(),
                emptyLabel: 'Aucune restitution terminée',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tab list ────────────────────────────────────────────────────────────────
class _RestitutionTab extends ConsumerWidget {
  const _RestitutionTab({required this.items, required this.emptyLabel});
  final List<Restitution> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 56,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              emptyLabel,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    // Consumer pour avoir accès à ref dans le callback onRefresh
    return RefreshIndicator(
      onRefresh: () => ref.read(restitutionListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _RestitutionCard(restitution: items[i]),
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────
class _RestitutionCard extends StatelessWidget {
  const _RestitutionCard({required this.restitution});
  final Restitution restitution;

  Color _statusColor(BuildContext context, String status) {
    final cs = Theme.of(context).colorScheme;
    return switch (status) {
      'requested' => cs.primary,
      'verified'  => Colors.orange,
      'completed' => Colors.green,
      'disputed'  => cs.error,
      'cancelled' => cs.onSurface.withValues(alpha: 0.4),
      _           => cs.outline,
    };
  }

  IconData _statusIcon(String status) => switch (status) {
        'requested' => Icons.pending_outlined,
        'verified'  => Icons.verified_user_outlined,
        'completed' => Icons.check_circle_outline,
        'disputed'  => Icons.report_problem_outlined,
        'cancelled' => Icons.cancel_outlined,
        _           => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _statusColor(context, restitution.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/restitutions/${restitution.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_statusIcon(restitution.status),
                    color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restitution #${restitution.id.length >= 8 ? restitution.id.substring(0, 8) : restitution.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            restitution.statusLabel,
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (restitution.meetingLocation != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: cs.onSurface.withValues(alpha: 0.4)),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              restitution.meetingLocation!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.5)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text('Erreur de chargement',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Recharger'),
            ),
          ],
        ),
      ),
    );
  }
}
