import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/appear.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/media_url.dart';
import '../../matches/providers/matches_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/declaration.dart';
import '../providers/declarations_provider.dart';
import '../widgets/declaration_card.dart';

class DeclarationsListPage extends ConsumerWidget {
  const DeclarationsListPage({super.key});

  /// Propose de déclarer un document TROUVÉ ou PERDU (F-10 / F-13).
  void _chooseType(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(AppLocalizations.of(ctx).declChooseTitle,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Icon(Icons.travel_explore, color: cs.primary),
              ),
              title: Text(AppLocalizations.of(ctx).declChooseFound,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(AppLocalizations.of(ctx).declChooseFoundSub),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/declarations/new?type=found');
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                child: const Icon(Icons.search_off, color: Colors.orange),
              ),
              title: Text(AppLocalizations.of(ctx).declChooseLost,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(AppLocalizations.of(ctx).declChooseLostSub),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/declarations/new?type=lost');
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primary.withValues(alpha: 0.15),
                child: Icon(Icons.auto_awesome_outlined, color: cs.primary),
              ),
              title: Text(AppLocalizations.of(ctx).mdocTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(AppLocalizations.of(ctx).mdocChooseSub),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/declarations/multi');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(declarationsProvider);
    final cs = Theme.of(context).colorScheme;
    final limits = ref.watch(declarationLimitsProvider).valueOrNull;
    final atLimit =
        limits != null && limits.activeCount >= limits.limit;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(declarationsProvider);
            ref.invalidate(declarationLimitsProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: _GreetingHeader()),
              const SliverToBoxAdapter(child: _HeroCard()),
              const SliverToBoxAdapter(child: _ProfileBanner()),
              ...async.when(
                loading: () => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (e, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppErrorView(
                      error: e,
                      onRetry: () => ref.invalidate(declarationsProvider),
                    ),
                  ),
                ],
                data: (items) {
                  final grouped = groupDeclarations(items);
                  return [
                  SliverToBoxAdapter(child: _StatsRow(items: items)),
                  if (items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color:
                                      cs.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.folder_open_outlined,
                                    size: 42,
                                    color: cs.primary
                                        .withValues(alpha: 0.6)),
                              ),
                              const SizedBox(height: 16),
                              Text(AppLocalizations.of(context).declEmptyTitle,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                  AppLocalizations.of(context).declEmptySubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.5))),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => context
                                    .go('/declarations/new?type=lost'),
                                icon: const Icon(Icons.search),
                                label: Text(
                                    AppLocalizations.of(context).declEmptyCta),
                              ),
                              const SizedBox(height: 24),
                            ]),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(AppLocalizations.of(context).declMine,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                            ),
                            // ── Chip compteur « 2 / 3 déclarations actives » ──
                            if (limits != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: (atLimit
                                          ? Colors.orange
                                          : AppColors.kGreenDark)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    '${limits.activeCount} / ${limits.limit} ${AppLocalizations.of(context).declActive}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: atLimit
                                            ? Colors.orange
                                            : AppColors.kGreenDark)),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Tooltip(
                              message: atLimit
                                  ? AppLocalizations.of(context).declLimitReached
                                  : AppLocalizations.of(context).declNew,
                              child: TextButton.icon(
                                onPressed: atLimit
                                    ? null
                                    : () => _chooseType(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(AppLocalizations.of(context).declNew),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList.separated(
                        itemCount: grouped.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final entry = grouped[i];
                          return Appear(
                            delay: Duration(
                                milliseconds: (i * 45).clamp(0, 400)),
                            child: entry.isDossier
                                ? _DossierHomeCard(
                                    docs: entry.docs,
                                    onTap: () => context.push(
                                        '/declarations/dossier/${entry.groupId}'),
                                  )
                                : DeclarationCard(
                                    declaration: entry.docs.first,
                                    onTap: () => context.go(
                                        '/declarations/${entry.docs.first.id}'),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête d'accueil : avatar, salutation personnalisée et ville (F-02).
class _GreetingHeader extends ConsumerWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final name = profile?.fullName.trim() ?? '';
    final firstName = name.isEmpty ? null : name.split(RegExp(r'\s+')).first;
    final initials = name.isEmpty
        ? '?'
        : name
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.primaryContainer,
              foregroundImage: (profile?.avatarUrl?.isNotEmpty ?? false)
                  ? CachedNetworkImageProvider(mediaUrl(profile!.avatarUrl))
                  : null,
              child: Text(initials,
                  style: TextStyle(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  final greet = AppLocalizations.of(context)
                      .greeting(DateTime.now().hour);
                  return Text(
                    firstName == null ? greet : '$greet $firstName',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  );
                }),
                if (profile?.city?.isNotEmpty ?? false)
                  Text(profile!.city!,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          _NotificationBell(
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}

/// Cloche de notifications avec badge du nombre en attente.
class _NotificationBell extends ConsumerWidget {
  final VoidCallback onTap;
  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(notificationsProvider).valueOrNull?.length ?? 0;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Stack(clipBehavior: Clip.none, children: [
        const Icon(Icons.notifications_outlined,
            color: AppColors.kGreenDark),
        if (count > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints:
                  const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Carte héro « J'ai trouvé / J'ai perdu » — point d'entrée principal
/// des deux parcours (F-10 / F-13).
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradColors = isDark
        ? [Theme.of(context).colorScheme.surface, AppColors.surfaceVariant]
        : const [Color(0xFF01353A), Color(0xFF01565B)];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).homeHeroTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(AppLocalizations.of(context).homeHeroSubtitle,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: AppLocalizations.of(context).homeFound,
                  icon: Icons.document_scanner_outlined,
                  background: AppColors.kGreen,
                  foreground: Colors.white,
                  onTap: () => context.go('/declarations/new?type=found'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: AppLocalizations.of(context).homeLost,
                  icon: Icons.search,
                  background: Colors.white,
                  foreground: AppColors.kGreenDark,
                  onTap: () => context.go('/declarations/new?type=lost'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  const _HeroButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 7),
              Text(label,
                  style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rangée de statistiques : actives / matchées / clôturées (F-24).
class _StatsRow extends StatelessWidget {
  final List<Declaration> items;
  const _StatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final active = items.where((d) => d.status == 'active').length;
    final matched = items.where((d) => d.status == 'matched').length;
    final closed = items.where((d) => d.status == 'closed').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          _StatCard(
              value: active,
              label: AppLocalizations.of(context).statActive,
              color: AppColors.kGreenDark),
          const SizedBox(width: 10),
          _StatCard(
              value: matched,
              label: AppLocalizations.of(context).statMatched,
              color: AppColors.secondary,
              onTap: () => context.go('/matches')),
          const SizedBox(width: 10),
          _StatCard(
              value: closed,
              label: AppLocalizations.of(context).statRestituted,
              color: AppColors.onSurface,
              onTap: () => context.push('/restitutions')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              children: [
                Text('$value',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau d'accueil invitant à compléter le profil (F-02).
/// Visible uniquement tant que le profil est incomplet.
class _ProfileBanner extends ConsumerWidget {
  const _ProfileBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (profile == null || profile.isProfileComplete) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Material(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.go('/profile'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.account_circle_outlined,
                    color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context).profileCompleteBanner,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).profileCompleteBannerSub,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.orange),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une entrée de la liste d'accueil : soit un document seul, soit un dossier
/// multi-documents (≥ 2 documents partageant le même group_id).
class DeclarationEntry {
  final List<Declaration> docs;
  const DeclarationEntry(this.docs);
  bool get isDossier => docs.length >= 2;
  String? get groupId => docs.first.groupId;
}

/// Regroupe les déclarations par dossier (group_id) en préservant l'ordre
/// d'apparition. Un group_id présent sur ≥ 2 documents forme un dossier.
List<DeclarationEntry> groupDeclarations(List<Declaration> decls) {
  final entries = <DeclarationEntry>[];
  final seen = <String>{};
  for (final d in decls) {
    final g = d.groupId;
    if (g == null || g.isEmpty) {
      entries.add(DeclarationEntry([d]));
      continue;
    }
    if (seen.contains(g)) continue;
    seen.add(g);
    final members = decls.where((x) => x.groupId == g).toList();
    entries.add(DeclarationEntry(members));
  }
  return entries;
}

/// Carte « dossier » sur l'accueil : résume plusieurs documents d'un même
/// propriétaire. Un tap ouvre le détail du dossier (tous les fichiers).
class _DossierHomeCard extends StatelessWidget {
  final List<Declaration> docs;
  final VoidCallback onTap;
  const _DossierHomeCard({required this.docs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final owner = docs.first.nomProprietaire;
    final types = docs.map((d) => d.documentLabel).toSet().join(' · ');
    final thumb = docs
        .map((d) => d.allPhotoUrls.isNotEmpty ? d.allPhotoUrls.first : null)
        .firstWhere((u) => u != null, orElse: () => null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: thumb != null
                    ? CachedNetworkImage(
                        imageUrl: mediaUrl(thumb),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                            Icons.folder_shared_outlined, color: cs.primary))
                    : Icon(Icons.folder_shared_outlined, color: cs.primary),
              ),
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${docs.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(l.dossierBadge,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.primary)),
                ),
                const SizedBox(height: 6),
                Text(owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${l.dossierDocsCount(docs.length)} · $types',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
        ]),
      ),
    );
  }
}
