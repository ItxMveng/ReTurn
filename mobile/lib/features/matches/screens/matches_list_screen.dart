import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/matches_provider.dart';
import '../data/models/match_model.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Correspondances')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (matches) => matches.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucune correspondance trouvée',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(matchesNotifierProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _MatchCard(match: matches[i]),
                ),
              ),
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final MatchModel match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = (match.score * 100).toStringAsFixed(0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Score : $score%',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Chip(
                  label: Text(match.status),
                  backgroundColor: match.status == 'pending'
                      ? Colors.orange.shade100
                      : Colors.green.shade100,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (match.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(matchesNotifierProvider.notifier)
                          .reject(match.id),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Rejeter',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ref
                          .read(matchesNotifierProvider.notifier)
                          .confirm(match.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
