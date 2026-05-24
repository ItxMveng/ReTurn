import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/matches_provider.dart';
import '../models/match_model.dart';

class MatchesListPage extends ConsumerWidget {
  const MatchesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Matchs')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.compare_arrows,
                      size: 64,
                      color: cs.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text('Aucun match pour le moment',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                      'Les matchs apparaissent automatiquement\nlorsqu\'un document correspond',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: cs.onSurface.withOpacity(0.5),
                          fontSize: 13)),
                ]),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(matchesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) => _MatchTile(
                      match: items[i],
                      onTap: () =>
                          context.go('/matches/${items[i].id}')),
                ),
              ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  const _MatchTile({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = match.scorePercent >= 80
        ? Colors.green
        : match.scorePercent >= 60
            ? Colors.orange
            : Colors.red;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Row(children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: match.score,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeWidth: 4,
                ),
              ),
              Text('${match.scorePercent}%',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Match #${match.id.substring(0, 8)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                    '${match.createdAt.day}/${match.createdAt.month}/${match.createdAt.year}',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          Chip(
            label: Text(match.status,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: match.isConfirmed
                        ? Colors.green
                        : cs.onSurface.withOpacity(0.6))),
            backgroundColor:
                match.isConfirmed ? Colors.green.withOpacity(0.1) : null,
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }
}
