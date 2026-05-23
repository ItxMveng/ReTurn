import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/matching/providers/match_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/models/match.dart';
import 'package:docretour/shared/widgets/document_type_dropdown.dart';

class MatchesListScreen extends ConsumerWidget {
  const MatchesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final asyncMatches = ref.watch(matchListProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.matchesTitle),
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(matchListProvider.notifier).refresh(),
          ),
        ],
      ),
      body: asyncMatches.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (matches) {
          if (matches.isEmpty) return _EmptyState(l: l);
          return RefreshIndicator(
            color: kGreen,
            onRefresh: () => ref.read(matchListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _MatchCard(match: matches[i], l: l),
            ),
          );
        },
      ),
    );
  }
}

class _MatchCard extends ConsumerWidget {
  final Match match;
  final AppLocalizations l;
  const _MatchCard({required this.match, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final docType = match.declarationFound?.documentType ??
        match.declarationLost?.documentType ??
        '';

    return Container(
      decoration: BoxDecoration(
        color: cs.brightness == Brightness.light
            ? Colors.white
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
        boxShadow: cs.brightness == Brightness.light
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/matches/${match.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.compare_arrows,
                        color: kGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      documentTypeLabel(docType),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: cs.onSurface),
                    ),
                  ),
                  _ScoreBadge(match.scorePercent),
                ],
              ),
              const SizedBox(height: 12),
              _MatchRow(
                icon: Icons.search,
                color: kGreen,
                label: l.matchFound,
                declaration: match.declarationFound,
              ),
              const SizedBox(height: 6),
              _MatchRow(
                icon: Icons.report_outlined,
                color: const Color(0xFFEF4444),
                label: l.matchLost,
                declaration: match.declarationLost,
              ),
              if (match.isPending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            ref.read(matchListProvider.notifier).ignore(match.id),
                        icon: const Icon(Icons.close,
                            color: Color(0xFFEF4444), size: 18),
                        label: Text(l.matchIgnore,
                            style: const TextStyle(color: Color(0xFFEF4444))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(matchListProvider.notifier).confirm(match.id),
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(l.matchConfirm),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _StatusChip(match.status),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final dynamic declaration;

  const _MatchRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.declaration,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final number = declaration?.documentNumber;
    final owner = declaration?.ownerName;
    final info = [if (number != null) 'N° $number', if (owner != null) owner]
        .join(' — ');
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text('$label : ',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
          child: Text(
            info.isEmpty ? '—' : info,
            style: TextStyle(
                fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int percent;
  const _ScoreBadge(this.percent);

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? kGreen
        : percent >= 60
            ? const Color(0xFFF59E0B)
            : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        '$percent%',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'confirmed' => ('Confirmé', kGreen),
      'ignored'   => ('Ignoré', Colors.grey),
      'closed'    => ('Clôturé', Colors.blueGrey),
      _           => ('En attente', const Color(0xFF3B82F6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l;
  const _EmptyState({required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.compare_arrows, size: 50, color: kGreen),
            ),
            const SizedBox(height: 20),
            Text(l.matchesEmpty,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 10),
            Text(l.matchesEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5), height: 1.5)),
          ],
        ),
      ),
    );
  }
}
