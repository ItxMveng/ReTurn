import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';

/// Shell principal avec BottomNavigationBar persistante
class ScaffoldShell extends StatelessWidget {
  const ScaffoldShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _Tab(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Accueil', path: RoutePaths.home),
    _Tab(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Déclarations', path: RoutePaths.declarations),
    _Tab(icon: Icons.compare_arrows_outlined, activeIcon: Icons.compare_arrows_rounded, label: 'Matchs', path: RoutePaths.matches),
    _Tab(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Messages', path: RoutePaths.messages),
    _Tab(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profil', path: RoutePaths.profile),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon, color: AppColors.primary),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.icon, required this.activeIcon, required this.label, required this.path});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}
