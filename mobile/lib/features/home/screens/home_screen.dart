import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/profile/providers/profile_provider.dart';
import 'package:docretour/features/restitution/providers/restitution_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/widgets/guided_tour.dart';
import 'package:docretour/shared/widgets/notification_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting(BuildContext context) {
    final hour = DateTime.now().hour;
    final lang = Localizations.localeOf(context).languageCode;
    if (lang == 'en') {
      if (hour >= 5 && hour < 12) return 'Good morning';
      if (hour >= 12 && hour < 18) return 'Good afternoon';
      if (hour >= 18) return 'Good evening';
      return 'Good night';
    }
    if (hour >= 5 && hour < 12) return 'Bonjour';
    if (hour >= 12 && hour < 18) return 'Bon après-midi';
    if (hour >= 18) return 'Bonsoir';
    return 'Bonne nuit';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final profile = ref.watch(profileProvider).valueOrNull;
    final firstName = profile?.fullName.split(' ').first ?? '';

    // Nombre de restitutions actives pour le badge
    final activeCount = ref.watch(activeRestituionsProvider).length;

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final gradColors = isDark
        ? [cs.surface, cs.surfaceContainerHighest]
        : const [Color(0xFF0A1F16), Color(0xFF0D2B1F)];

    return GuidedTourOverlay(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradColors,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 12, 32),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstName.isNotEmpty
                                    ? '${_greeting(context)}, $firstName 👋'
                                    : '${_greeting(context)} 👋',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.homeQuestion,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        NotificationBadge(
                          onTap: () => context.push('/matches'),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () => context.push('/matches'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined,
                              color: Colors.white),
                          onPressed: () => context.push('/settings'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // ── Cards ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ActionCard(
                    icon: Icons.search,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                    title: l.homeFoundDoc,
                    subtitle: l.homeFoundDocSub,
                    onTap: () => context.push('/declarations/new/found'),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.report_outlined,
                    gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    title: l.homeLostDoc,
                    subtitle: l.homeLostDocSub,
                    onTap: () => context.push('/declarations/new/lost'),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.list_alt_outlined,
                    gradient: LinearGradient(
                        colors: [cs.secondary,
                            cs.secondary.withValues(alpha: 0.75)]),
                    title: l.homeDeclarations,
                    subtitle: l.homeDeclarationsSub,
                    onTap: () => context.push('/declarations'),
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    icon: Icons.compare_arrows,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                    title: l.homeMatches,
                    subtitle: l.homeMatchesSub,
                    onTap: () => context.push('/matches'),
                  ),
                  const SizedBox(height: 16),
                  // ── Nouvelle carte Restitutions ──────────────────
                  _ActionCard(
                    icon: Icons.assignment_turned_in_outlined,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0891B2), Color(0xFF0E7490)]),
                    title: 'Restitutions',
                    subtitle: 'Suivez vos remises de documents',
                    badge: activeCount > 0 ? activeCount : null,
                    onTap: () => context.push('/restitutions'),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ActionCard ────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int? badge;

  const _ActionCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: kGreen.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.brightness == Brightness.light
                ? Colors.white
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outline),
            boxShadow: cs.brightness == Brightness.light
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -6,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        decoration: BoxDecoration(
                          color: cs.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badge! > 99 ? '99+' : '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.55),
                          fontSize: 13,
                          height: 1.4,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_outlined,
                  color: cs.outline, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
