import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/matching/providers/match_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/models/match.dart';
import 'package:docretour/shared/widgets/document_type_dropdown.dart';

// Provider local pour tracker les IDs en cours d'action (anti-double-tap)
final _loadingMatchIdsProvider =
    StateProvider<Set<String>>((ref) => const {});

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
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.read(matchListProvider.notifier).refresh(),
        ),
        data: (matches) {
          if (matches.isEmpty) return _EmptyState(l: l);
          return RefreshIndicator(
            color: kGreen,
            onRefresh: () =>
                ref.read(matchListProvider.notifier).refresh(),
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
    final loadingIds = ref.watch(_loadingMatchIdsProvider);
    final isLoading = loadingIds.contains(match.id);

    final docType = match.declarationFound?.documentType ??
        match.declarationLost?.documentType ??
        '';

    Future<void> act(String action) async {
      if (isLoading) return;
      ref
          .read(_loadingMatchIdsProvider.notifier)
          .update((s) => {...s, match.id});
      try {
        if (action == 'confirmed') {
          await ref.read(matchListProvider.notifier).confirm(match.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.matchConfirmedSuccess)),
                  ],
                ),
                backgroundColor: kGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          await ref.read(matchListProvider.notifier).ignore(match.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(l.matchIgnoredSuccess)),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: cs.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        ref
            .read(_loadingMatchIdsProvider.notifier)
            .update((s) => s.difference({match.id}));
      }
    }

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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kGreen),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => act('ignored'),
                                icon: const Icon(Icons.close,
                                    color: Color(0xFFEF4444), size: 18),
                                label: Text(l.matchIgnore,
                                    style: const TextStyle(
                                        color: Color(0xFFEF4444))),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFFEF4444)),
                                  minimumSize: const Size(0, 40),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => act('confirmed'),
                                icon: const Icon(Icons.check, size: 18),
                                label: Text(l.matchConfirm),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                ),
                              ),
                            ),
                          ],
                        ),
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
    final number = declaration?.documentNumber as String?;
    final owner = declaration?.ownerName as String?;
    final subtitle = [number, owner].whereType<String>().join(' · ');

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text('$label : ',
            style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(
            subtitle.isNotEmpty ? subtitle : '—',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: cs.onSurface),
          ),
        ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int percent;
  const _ScoreBadge(this.percent);

  Color _color() =>
      percent >= 80 ? kGreen : percent >= 60 ? const Color(0xFFF59E0B) : Colors.grey;

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      'confirmed' => ('Confirmé', kGreen),
      'ignored' => ('Ignoré', cs.onSurface.withValues(alpha: 0.4)),
      'completed' => ('Complété', const Color(0xFF0891B2)),
      _ => (status, cs.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows,
              size: 64, color: cs.onSurface.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            l.matchesEmptyTitle,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            l.matchesEmptySub,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

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
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 13)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
