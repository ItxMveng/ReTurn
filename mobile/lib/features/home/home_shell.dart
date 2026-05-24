import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  static const _tabs = [
    _Tab('/declarations', Icons.description_outlined, Icons.description, 'Documents'),
    _Tab('/matches', Icons.compare_arrows_outlined, Icons.compare_arrows, 'Matchs'),
    _Tab('/messages', Icons.chat_bubble_outline, Icons.chat_bubble, 'Messages'),
    _Tab('/profile', Icons.person_outline, Icons.person, 'Profil'),
  ];

  int _indexOf(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _indexOf(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: child,
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
                  selectedIcon:
                      Icon(e.value.selectedIcon, color: cs.primary),
                  label: e.value.label,
                ))
            .toList(),
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
