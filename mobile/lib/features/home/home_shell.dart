import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/guided_tour.dart';
import '../profile/pages/profile_page.dart';
import '../profile/providers/profile_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  /// Une seule invite de complétion de profil par lancement de l'app.
  static bool _profilePromptShown = false;

  static const _tabs = [
    _Tab('/declarations', Icons.description_outlined, Icons.description, 'Documents'),
    _Tab('/matches', Icons.compare_arrows_outlined, Icons.compare_arrows, 'Matchs'),
    _Tab('/messages', Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
    _Tab('/profile', Icons.person_outline, Icons.person, 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    // Profil déjà en cache au montage (ref.listen ne couvre que les
    // changements ultérieurs) → vérification initiale.
    Future.microtask(() {
      if (!mounted || _profilePromptShown) return;
      final profile = ref.read(profileProvider).valueOrNull;
      if (profile != null && !profile.isProfileComplete) {
        _profilePromptShown = true;
        showCompleteProfileSheet(context);
      }
    });
  }

  int _indexOf(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Premier lancement post-inscription : profil incomplet → bottom sheet
    // non-ignorable « Complétez votre profil en 1 minute ».
    ref.listen(profileProvider, (_, next) {
      final profile = next.valueOrNull;
      if (profile == null || profile.isProfileComplete || _profilePromptShown) {
        return;
      }
      _profilePromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showCompleteProfileSheet(context);
      });
    });

    final idx = _indexOf(context);
    final cs = Theme.of(context).colorScheme;
    return GuidedTourOverlay(
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          indicatorColor: cs.primary.withOpacity(0.12),
          destinations: _tabs
              .asMap()
              .entries
              .map((e) => NavigationDestination(
                    icon: Icon(e.value.icon),
                    selectedIcon: Icon(e.value.selectedIcon, color: cs.primary),
                    label: e.value.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Tab(this.path, this.icon, this.selectedIcon, this.label);
}
