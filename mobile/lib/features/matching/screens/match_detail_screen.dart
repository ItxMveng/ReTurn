import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/matching/providers/match_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/models/declaration.dart';
import 'package:docretour/shared/widgets/document_type_dropdown.dart';

// Provider dédié pour fetch un match individuel si absent du cache
final _singleMatchProvider =
    FutureProvider.family.autoDispose<dynamic, String>((ref, id) async {
  // On essaie d'abord le cache de la liste
  final cached = ref
      .watch(matchListProvider)
      .valueOrNull
      ?.where((m) => m.id == id)
      .firstOrNull;
  if (cached != null) return cached;
  // Sinon fetch direct via le repository
  final repo = ref.read(matchRepositoryProvider);
  return repo.getMatch(id);
});

class MatchDetailScreen extends ConsumerWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final asyncMatch = ref.watch(_singleMatchProvider(matchId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        title: const Text('Détail du match'),
        actions: [
          asyncMatch.whenOrNull(
            data: (match) => Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _scoreColor(match?.scorePercent ?? 0)
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _scoreColor(match?.scorePercent ?? 0), width: 1),
              ),
              child: Text(
                '${match?.scorePercent ?? 0}%',
                style: TextStyle(
                    color: _scoreColor(match?.scorePercent ?? 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: asyncMatch.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: cs.error),
                const SizedBox(height: 12),
                Text('Impossible de charger ce match.',
                    style: TextStyle(color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(_singleMatchProvider(matchId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (match) {
          if (match == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off,
                      size: 56,
                      color: cs.onSurface.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('Match introuvable',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  const SizedBox(height: 16),
                  TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retour')),
                ],
              ),
            );
          }
          return _MatchDetailBody(match: match, matchId: matchId, l: l);
        },
      ),
    );
  }

  Color _scoreColor(int p) =>
      p >= 80 ? kGreen : p >= 60 ? const Color(0xFFF59E0B) : Colors.grey;
}

// ── Body ─────────────────────────────────────────────────────────────────────
class _MatchDetailBody extends ConsumerWidget {
  final dynamic match;
  final String matchId;
  final AppLocalizations l;
  const _MatchDetailBody(
      {required this.match, required this.matchId, required this.l});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isActionLoading = ref.watch(
      _actionLoadingProvider(matchId),
    );

    Future<void> doConfirm() async {
      ref.read(_actionLoadingProvider(matchId).notifier).state = true;
      try {
        await ref.read(matchListProvider.notifier).confirm(matchId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.white, size: 18),
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
          context.pop();
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
        ref.read(_actionLoadingProvider(matchId).notifier).state = false;
      }
    }

    Future<void> doIgnore() async {
      ref.read(_actionLoadingProvider(matchId).notifier).state = true;
      try {
        await ref.read(matchListProvider.notifier).ignore(matchId);
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
          context.pop();
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
        ref.read(_actionLoadingProvider(matchId).notifier).state = false;
      }
    }

    return SingleChildScrollView(
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isActionLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: kGreen),
                    ),
                  )
                : _Actions(
                    match: match,
                    matchId: matchId,
                    l: l,
                    onConfirm: doConfirm,
                    onIgnore: doIgnore,
                  ),
          ),
        ],
      ),
    );
  }
}

final _actionLoadingProvider =
    StateProvider.family<bool, String>((ref, _) => false);

class _Actions extends StatelessWidget {
  final dynamic match;
  final String matchId;
  final AppLocalizations l;
  final VoidCallback onConfirm;
  final VoidCallback onIgnore;
  const _Actions({
    required this.match,
    required this.matchId,
    required this.l,
    required this.onConfirm,
    required this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    if (match.status == 'confirmed') {
      return ElevatedButton.icon(
        onPressed: () => context.push(
          '/matches/$matchId/chat',
          extra: documentTypeLabel(
            match.declarationFound?.documentType ??
                match.declarationLost?.documentType ??
                '',
          ),
        ),
        icon: const Icon(Icons.chat_outlined),
        label: Text(l.matchOpenChat),
      );
    }
    if (match.isPending) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l.matchConfirmThis),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push(
              '/matches/$matchId/chat',
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
            onPressed: onIgnore,
            icon: const Icon(Icons.cancel_outlined,
                color: Color(0xFFEF4444)),
            label: Text(l.matchIgnore,
                style: const TextStyle(color: Color(0xFFEF4444))),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444))),
          ),
        ],
      );
    }
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }
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
