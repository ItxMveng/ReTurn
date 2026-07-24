import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/appear.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/state_views.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/matches_provider.dart';
import '../repositories/matches_repository.dart';
import '../models/match.dart';

class MatchesListPage extends ConsumerStatefulWidget {
  const MatchesListPage({super.key});

  @override
  ConsumerState<MatchesListPage> createState() => _MatchesListPageState();
}

class _MatchesListPageState extends ConsumerState<MatchesListPage> {
  String _filter = 'all'; // all | pending | confirmed

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(matchesProvider);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final myId = ref.watch(profileProvider).valueOrNull?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l.matchesTitle2)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
            error: e, onRetry: () => ref.invalidate(matchesProvider)),
        data: (items) {
          final filtered = switch (_filter) {
            'pending' => items.where((m) => m.isPending).toList(),
            'confirmed' => items.where((m) => m.isConfirmed).toList(),
            _ => items,
          };
          return Column(
            children: [
              // ── Filtres (F-24) ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l.matchFilterAll,
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l.matchFilterPending,
                      selected: _filter == 'pending',
                      onTap: () => setState(() => _filter = 'pending'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l.matchFilterConfirmed,
                      selected: _filter == 'confirmed',
                      onTap: () => setState(() => _filter = 'confirmed'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _ScanningIndicator(),
                              const SizedBox(height: 20),
                              Text(l.matchesEmpty,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                  l.matchesSearching,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 13)),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () =>
                                    context.go('/declarations'),
                                icon: const Icon(Icons.add),
                                label: Text(l.matchDeclareDoc),
                              ),
                            ]),
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(matchesProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => Appear(
                            delay: Duration(
                                milliseconds: (i * 45).clamp(0, 400)),
                            child: _MatchTile(
                                match: filtered[i],
                                myId: myId,
                                onTap: () => context
                                    .go('/matches/${filtered[i].id}')),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Animation de « scan » pour l'empty state : anneau qui pulse en continu,
/// signale que la recherche de correspondances est active.
class _ScanningIndicator extends StatefulWidget {
  const _ScanningIndicator();

  @override
  State<_ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<_ScanningIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return SizedBox(
          width: 96,
          height: 96,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 40 + 56 * t,
              height: 40 + 56 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.primary.withValues(alpha: (1 - t) * 0.5),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.radar, color: cs.primary, size: 28),
            ),
          ]),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.kGreenDark : AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.kGreenDark : AppColors.outline),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.onSurfaceVariant)),
        ),
      ),
    );
  }
}

/// Masque partiellement un nom tant que le match n'est pas confirmé
/// (anti-scraping) : « Jean Mbarga » → « Jean M••••• ».
String _maskName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final masked = <String>[];
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    if (i == 0 || p.length <= 1) {
      masked.add(p);
    } else {
      final dots = p.length - 1 > 6 ? 6 : p.length - 1;
      masked.add('${p[0]}${'•' * dots}');
    }
  }
  return masked.join(' ');
}

class _MatchTile extends StatelessWidget {
  final Match match;
  final String myId;
  final VoidCallback onTap;
  const _MatchTile(
      {required this.match, required this.myId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scorePercent = (match.score * 100).round();
    // Barre colorée : rouge < 55 %, orange < 70 %, vert ≥ 70 %.
    final color = match.score >= 0.70
        ? AppColors.kGreen
        : match.score >= 0.55
            ? AppColors.secondary
            : AppColors.error;
    final docLabel = AppLocalizations.of(context).docType(match.documentType);
    final rawName = (match.otherUserName?.trim().isNotEmpty ?? false)
        ? match.otherUserName!.trim()
        : AppLocalizations.of(context).commonUser;
    // Nom partiellement masqué tant que le match n'est pas confirmé.
    final displayName =
        match.isConfirmed ? rawName : _maskName(rawName);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.badge_outlined,
                    color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(docLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                        match.createdAt == null
                            ? displayName
                            : '$displayName · ${match.createdAt!.day}/${match.createdAt!.month}/${match.createdAt!.year}',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(match: match, myId: myId),
            ]),
            const SizedBox(height: 12),
            // ── Barre de score de confiance ──
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: match.score.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$scorePercent%',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Badge d'état du match, en français (F-24).
/// Distingue « à confirmer » de « en attente de l'autre partie ».
class _StatusChip extends StatelessWidget {
  final Match match;
  final String myId;
  const _StatusChip({required this.match, required this.myId});

  @override
  Widget build(BuildContext context) {
    // Le flux pivote sur la vérification d'identité du PROPRIÉTAIRE :
    // - proprio : il doit vérifier son identité ;
    // - trouveur : il attend simplement cette vérification.
    final isOwner = match.isOwner(myId);
    final l = AppLocalizations.of(context);
    final (label, color) = switch (match.status) {
      'pending' when isOwner => (l.matchVerifyId, AppColors.secondary),
      'pending' => (l.matchStatusAwaitOwner, AppColors.onSurfaceVariant),
      'confirmed' => (l.matchStatusVerifiedChat, AppColors.kGreenDark),
      'ignored' => (l.matchStatusIgnored, AppColors.onSurfaceVariant),
      'closed' => (l.matchStatusClosed, AppColors.onSurfaceVariant),
      _ => (match.status, AppColors.onSurfaceVariant),
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Page Notifications — accessible depuis la cloche de l'accueil.
// ═══════════════════════════════════════════════════════════════════════════

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final hm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (day == today) return 'Aujourd\'hui à $hm';
    if (day == today.subtract(const Duration(days: 1))) return 'Hier à $hm';
    return '${d.day}/${d.month}/${d.year} à $hm';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.notifTitle),
        actions: [
          if ((async.valueOrNull?.isNotEmpty ?? false))
            TextButton(
              onPressed: () async {
                await ref
                    .read(matchesRepositoryProvider)
                    .clearNotifications();
                ref.invalidate(notificationsProvider);
              },
              child: Text(l.notifClearAll),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wifi_off,
                size: 40, color: cs.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(l.notifLoadError),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(notificationsProvider),
              child: Text(l.retry),
            ),
          ]),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_none_rounded,
                      size: 42, color: cs.primary.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                Text(l.notifEmpty,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  l.notifEmptySub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontSize: 13),
                ),
              ]),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = items[i];
                final type = n['type'] as String? ?? '';
                final docLabel =
                    l.docType(n['document_type'] as String? ?? 'Document');
                final score = (n['score'] as num?)?.toDouble();
                final matchId = n['match_id'] as String?;
                final isMatch = type == 'match_found';
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        isMatch
                            ? Icons.compare_arrows_rounded
                            : Icons.notifications_outlined,
                        color: cs.primary),
                  ),
                  title: Text(
                    isMatch ? l.notifMatchFound : l.notifGeneric,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMatch && score != null
                            ? '$docLabel · ${(score * 100).round()}${l.notifCorrespondence}'
                            : docLabel,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      if ((n['created_at'] as String?) != null)
                        Text(_formatDate(n['created_at'] as String?),
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    cs.onSurface.withValues(alpha: 0.45))),
                    ],
                  ),
                  trailing: matchId != null
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: matchId != null
                      ? () => context.push('/matches/$matchId')
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
