import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/matching/providers/match_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/models/declaration.dart';
import 'package:docretour/shared/widgets/document_type_dropdown.dart';

class MatchDetailScreen extends ConsumerWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final asyncMatches = ref.watch(matchListProvider);
    final match = asyncMatches.valueOrNull
        ?.where((m) => m.id == matchId)
        .firstOrNull;

    if (match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail du match')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        title: const Text('Détail du match'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _scoreColor(match.scorePercent).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _scoreColor(match.scorePercent), width: 1),
            ),
            child: Text(
              '${match.scorePercent}%',
              style: TextStyle(
                  color: _scoreColor(match.scorePercent),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (match.declarationFound != null)
              _DeclarationCard(
                  declaration: match.declarationFound!, type: 'found'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Divider(color: cs.outline)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.compare_arrows,
                        color: kGreen, size: 22),
                  ),
                ),
                Expanded(child: Divider(color: cs.outline)),
              ],
            ),
            const SizedBox(height: 16),
            if (match.declarationLost != null)
              _DeclarationCard(
                  declaration: match.declarationLost!, type: 'lost'),
            const SizedBox(height: 32),
            if (match.status == 'confirmed') ...[
              ElevatedButton.icon(
                onPressed: () => context.push(
                  '/matches/${match.id}/chat',
                  extra: documentTypeLabel(
                    match.declarationFound?.documentType ??
                        match.declarationLost?.documentType ??
                        '',
                  ),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: Text(l.matchOpenChat),
              ),
            ] else if (match.isPending) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await ref
                      .read(matchListProvider.notifier)
                      .confirm(match.id);
                  if (context.mounted) context.pop();
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(l.matchConfirmThis),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/matches/${match.id}/chat',
                  extra: documentTypeLabel(
                    match.declarationFound?.documentType ??
                        match.declarationLost?.documentType ??
                        '',
                  ),
                ),
                icon: const Icon(Icons.chat_outlined),
                label: Text(l.matchOpenChat),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(matchListProvider.notifier)
                      .ignore(match.id);
                  if (context.mounted) context.pop();
                },
                icon: const Icon(Icons.cancel_outlined,
                    color: Color(0xFFEF4444)),
                label: Text(l.matchIgnore,
                    style: const TextStyle(color: Color(0xFFEF4444))),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444))),
              ),
            ] else
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    'Statut : ${match.status}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int p) =>
      p >= 80 ? kGreen : p >= 60 ? const Color(0xFFF59E0B) : Colors.grey;
}

class _DeclarationCard extends StatelessWidget {
  final Declaration declaration;
  final String type;

  const _DeclarationCard({required this.declaration, required this.type});

  @override
  Widget build(BuildContext context) {
    final isFound = type == 'found';
    final color = isFound ? kGreen : const Color(0xFFEF4444);
    final label = isFound ? 'Document trouvé' : 'Document perdu';
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.brightness == Brightness.light
            ? Colors.white
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                      isFound ? Icons.search : Icons.report_outlined,
                      color: color,
                      size: 20),
                ),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ),
            Divider(height: 20, color: cs.outline),
            _Row('Type', documentTypeLabel(declaration.documentType)),
            if (declaration.documentNumber != null)
              _Row('Numéro', declaration.documentNumber!),
            if (declaration.ownerName != null)
              _Row('Titulaire', declaration.ownerName!),
            if (declaration.locationDescription != null)
              _Row('Lieu', declaration.locationDescription!),
            if (declaration.description != null)
              _Row('Description', declaration.description!),
            if (declaration.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: declaration.photoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      declaration.photoUrls[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.broken_image_outlined,
                            color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label :',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 13)),
          ),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface))),
        ],
      ),
    );
  }
}
