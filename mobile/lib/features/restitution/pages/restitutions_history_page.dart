import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/appear.dart';
import '../models/restitution.dart';
import '../repositories/restitution_repository.dart';

/// Historique des restitutions (F-35).
class RestitutionsHistoryPage extends ConsumerWidget {
  const RestitutionsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(restitutionsProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes restitutions')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history,
                      size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
                  const SizedBox(height: 12),
                  const Text('Aucune restitution',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Vos restitutions apparaîtront ici.',
                      style:
                          TextStyle(color: cs.onSurface.withValues(alpha: 0.5))),
                ]),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(restitutionsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => i == 0
                      ? _StatsRow(items: items)
                      : Appear(
                          delay: Duration(
                              milliseconds: ((i - 1) * 45).clamp(0, 360)),
                          child: _Tile(r: items[i - 1]),
                        ),
                ),
              ),
      ),
    );
  }
}

/// Rangée de statistiques : réussies / en cours / note moyenne (F-35).
class _StatsRow extends StatelessWidget {
  final List<Restitution> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = items.where((r) => r.status == 'completed').length;
    final ongoing = items
        .where((r) => r.status == 'pending' || r.status == 'in_progress')
        .length;
    final ratings = items
        .expand((r) => [r.ratingByOwner, r.ratingByFinder])
        .whereType<int>()
        .toList();
    final avg = ratings.isEmpty
        ? null
        : ratings.reduce((a, b) => a + b) / ratings.length;

    Widget cell(String value, String label, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.55))),
            ]),
          ),
        );

    return Row(children: [
      cell('$completed', 'Réussies', cs.primary),
      const SizedBox(width: 10),
      cell('$ongoing', 'En cours', Colors.orange),
      const SizedBox(width: 10),
      cell(avg == null ? '—' : '★ ${avg.toStringAsFixed(1)}',
          'Note moyenne', cs.onSurface),
    ]);
  }
}

class _Tile extends StatelessWidget {
  final Restitution r;
  const _Tile({required this.r});

  ({Color color, String label, IconData icon}) get _statusInfo => switch (r.status) {
        'completed' => (
            color: Colors.green,
            label: 'Terminée',
            icon: Icons.verified_rounded
          ),
        'cancelled' => (
            color: Colors.red,
            label: 'Annulée',
            icon: Icons.cancel_outlined
          ),
        _ => (
            color: Colors.orange,
            label: 'En cours',
            icon: Icons.schedule
          ),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = _statusInfo;
    final date = r.completedAt ?? r.createdAt;
    return InkWell(
      onTap: () => context.push('/restitution/${r.matchId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(children: [
          CircleAvatar(
            backgroundColor: s.color.withValues(alpha: 0.15),
            child: Icon(s.icon, color: s.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text('Restitution ${s.label.toLowerCase()}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  if (r.status == 'pending' || r.status == 'in_progress')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          '${(r.handoffConfirmedByOwner ? 1 : 0) + (r.handoffConfirmedByFinder ? 1 : 0)}/2',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: s.color)),
                    ),
                ]),
                const SizedBox(height: 2),
                Text(
                    r.meetingLocation?.isNotEmpty == true
                        ? r.meetingLocation!
                        : (date != null
                            ? '${date.day}/${date.month}/${date.year}'
                            : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurface.withValues(alpha: 0.55))),
                if (r.isCompleted &&
                    (r.ratingByOwner != null || r.ratingByFinder != null)) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      final rating = r.ratingByOwner ?? r.ratingByFinder ?? 0;
                      return Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: Colors.amber);
                    }),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
        ]),
      ),
    );
  }
}
