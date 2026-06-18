import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:return_mobile/core/theme/app_theme.dart';
import 'package:return_mobile/features/matching/providers/match_provider.dart';
import 'package:return_mobile/l10n/app_localizations.dart';
import 'package:return_mobile/shared/models/declaration.dart';
import 'package:return_mobile/shared/models/match.dart';
import 'package:return_mobile/shared/widgets/document_type_dropdown.dart';

// Provider family : fetch direct si absent du cache
final _matchDetailProvider = FutureProvider.family<Match, String>((ref, id) async {
  // D'abord chercher dans le cache de la liste
  final cached = ref.watch(matchListProvider).valueOrNull
      ?.where((m) => m.id == id)
      .firstOrNull;
  if (cached != null) return cached;
  // Sinon fetch direct depuis l'API (timeout 10s)
  return ref
      .read(matchRepositoryProvider)
      .getById(id)
      .timeout(const Duration(seconds: 10));
});

class MatchDetailScreen extends ConsumerWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final asyncMatch = ref.watch(_matchDetailProvider(matchId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        title: const Text('Détail du match'),
        actions: [
          asyncMatch.whenOrNull(
            data: (match) => Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          ) ?? const SizedBox.shrink(),
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
                Text('Impossible de charger ce match',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 6),
                Text(e.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(_matchDetailProvider(matchId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (match) => _MatchDetailBody(match: match, matchId: matchId, l: l),
      ),
    );
  }

  Color _scoreColor(int p) =>
      p >= 80 ? kGreen : p >= 60 ? const Color(0xFFF59E0B) : Colors.grey;
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _MatchDetailBody extends ConsumerStatefulWidget {
  final Match match;
  final String matchId;
  final AppLocalizations l;
  const _MatchDetailBody(
      {required this.match, required this.matchId, required this.l});

  @override
  ConsumerState<_MatchDetailBody> createState() => _MatchDetailBodyState();
}

class _MatchDetailBodyState extends ConsumerState<_MatchDetailBody> {
  bool _loadingConfirm = false;
  bool _loadingIgnore = false;

  void _showSnackbar(String msg, {Color? color, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10)],
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color ?? Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_loadingConfirm || _loadingIgnore) return;
    setState(() => _loadingConfirm = true);
    try {
      await ref.read(matchListProvider.notifier).confirm(widget.match.id);
      ref.invalidate(_matchDetailProvider(widget.matchId));
      _showSnackbar(
        'Match confirmé — vous pouvez maintenant discuter',
        color: kGreen,
        icon: Icons.check_circle,
      );
      if (mounted) context.pop();
    } catch (e) {
      _showSnackbar('Erreur : ${e.toString()}',
          color: Theme.of(context).colorScheme.error,
          icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _loadingConfirm = false);
    }
  }

  Future<void> _ignore() async {
    if (_loadingConfirm || _loadingIgnore) return;
    setState(() => _loadingIgnore = true);
    try {
      await ref.read(matchListProvider.notifier).ignore(widget.match.id);
      _showSnackbar('Match ignoré', icon: Icons.do_not_disturb);
      if (mounted) context.pop();
    } catch (e) {
      _showSnackbar('Erreur : ${e.toString()}',
          color: Theme.of(context).colorScheme.error,
          icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _loadingIgnore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final l = widget.l;
    final cs = Theme.of(context).colorScheme;

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
              onPressed: _loadingConfirm ? null : _confirm,
              icon: _loadingConfirm
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
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
              onPressed: _loadingIgnore ? null : _ignore,
              icon: _loadingIgnore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFFEF4444)))
                  : const Icon(Icons.cancel_outlined,
                      color: Color(0xFFEF4444)),
              label: Text(l.matchIgnore,
                  style: const TextStyle(color: Color(0xFFEF4444))),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444))),
            ),
          ] else
            Center(
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
            ),
        ],
      ),
    );
  }
}

// ── Declaration card ──────────────────────────────────────────────────────────

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
                  style: TextStyle(fontSize: 13, color: cs.onSurface))),
        ],
      ),
    );
  }
}
