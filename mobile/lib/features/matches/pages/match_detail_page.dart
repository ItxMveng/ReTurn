import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/matches_provider.dart';
import '../repositories/matches_repository.dart';

class MatchDetailPage extends ConsumerWidget {
  final String id;
  const MatchDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(matchDetailProvider(id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du match')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (m) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: m.score,
                        strokeWidth: 8,
                        backgroundColor:
                            cs.primary.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                    Text('${m.scorePercent.toInt()}%',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Score de correspondance',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 13)),
              ),
              const SizedBox(height: 28),
              _info('Statut', m.status),
              _info('Déclaration trouvée', m.foundDeclarationId),
              _info('Déclaration perdue', m.lostDeclarationId),
              if (m.createdAt != null)
                _info('Date',
                    '${m.createdAt!.day}/${m.createdAt!.month}/${m.createdAt!.year}'),
              const SizedBox(height: 24),
              if (m.isPending) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(matchesRepositoryProvider)
                        .confirmMatch(m.id);
                    ref.invalidate(matchDetailProvider(id));
                    if (context.mounted) {
                      context.go('/restitution/${m.id}');
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmer le match'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(matchesRepositoryProvider)
                        .rejectMatch(m.id);
                    ref.invalidate(matchesProvider);
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeter'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                ),
              ] else if (m.isConfirmed)
                ElevatedButton.icon(
                  onPressed: () =>
                      context.go('/messages/${m.id}'),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ouvrir la messagerie'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 140,
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.grey))),
            Expanded(
                child: Text(value,
                    style: const TextStyle(fontSize: 14))),
          ],
        ),
      );
}
