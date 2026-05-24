import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/matching_provider.dart';
import '../../matches/models/match.dart';

class MatchingScreen extends ConsumerWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchingProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Matchs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(matchingProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 48),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(matchingProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (matches) => matches.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compare_arrows,
                        size: 64, color: cs.onSurface.withOpacity(0.25)),
                    const SizedBox(height: 16),
                    const Text('Aucun match pour le moment',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Nous cherchons des correspondances\npour vos déclarations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: cs.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(matchingProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _MatchCard(match: matches[i]),
                ),
              ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});
  final Match match;

  Color _scoreColor(double score, ColorScheme cs) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return cs.error;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = (match.score * 100).toStringAsFixed(0);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _scoreColor(match.score, cs).withOpacity(0.15),
          child: Text(
            '$pct%',
            style: TextStyle(
              color: _scoreColor(match.score, cs),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(match.documentType,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(match.status),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/matches/${match.id}'),
      ),
    );
  }
}
