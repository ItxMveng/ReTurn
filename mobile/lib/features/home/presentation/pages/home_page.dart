import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../matches/application/matches_notifier.dart';
import '../../../declarations/application/declarations_notifier.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth   = ref.watch(authNotifierProvider);
    final matches = ref.watch(matchesNotifierProvider);
    final decls  = ref.watch(declarationsNotifierProvider);

    final displayName = auth.maybeWhen(
      authenticated: (user) => user.fullName ?? user.phoneNumber,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour 👋', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w400)),
                  Text(displayName, style: const TextStyle(fontSize: 16, color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats cards ──
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      icon: Icons.description_rounded,
                      label: 'Déclarations',
                      value: '${decls.items.length}',
                      color: AppColors.primary,
                      onTap: () => context.goNamed(RouteNames.declarations),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Matchs en attente',
                      value: '${matches.pending.length}',
                      color: AppColors.warning,
                      onTap: () => context.goNamed(RouteNames.matches),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      icon: Icons.handshake_rounded,
                      label: 'Restitutions',
                      value: '${matches.confirmed.length}',
                      color: AppColors.success,
                      onTap: () => context.goNamed(RouteNames.matches),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Terminées',
                      value: '${matches.completed.length}',
                      color: AppColors.secondary,
                      onTap: () => context.goNamed(RouteNames.matches),
                    )),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Actions rapides ──
                const Text('Actions rapides',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                const SizedBox(height: 14),
                _QuickAction(
                  icon: Icons.add_circle_rounded,
                  label: 'Nouvelle déclaration',
                  subtitle: 'Signaler un document trouvé ou perdu',
                  color: AppColors.primary,
                  onTap: () => context.pushNamed(RouteNames.newDeclaration),
                ),
                const SizedBox(height: 10),
                _QuickAction(
                  icon: Icons.search_rounded,
                  label: 'Voir mes correspondances',
                  subtitle: 'Consultez vos matchs détectés',
                  color: AppColors.warning,
                  onTap: () => context.goNamed(RouteNames.matches),
                ),
                const SizedBox(height: 10),
                _QuickAction(
                  icon: Icons.person_rounded,
                  label: 'Mon profil',
                  subtitle: 'Réputation et historique',
                  color: AppColors.secondary,
                  onTap: () => context.goNamed(RouteNames.profile),
                ),

                const SizedBox(height: 28),

                // ── Matchs récents ──
                if (matches.pending.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Matchs récents',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                      TextButton(
                        onPressed: () => context.goNamed(RouteNames.matches),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...matches.pending.take(3).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MatchPreview(
                      score: m.scorePercent,
                      docType: m.declarationFound?.documentLabel ?? '?',
                      onTap: () => context.pushNamed(RouteNames.matchDetail, pathParameters: {'id': m.id}),
                    ),
                  )),
                ],
              ]),
            ),
          ),
        ],
      ),

      // FAB déclaration rapide
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.newDeclaration),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Déclarer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.outline.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchPreview extends StatelessWidget {
  const _MatchPreview({required this.score, required this.docType, required this.onTap});
  final int score;
  final String docType;
  final VoidCallback onTap;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outline.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$score%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _color)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(docType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurface))),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.onSurfaceVariant.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
