import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/route_names.dart';
import '../theme/app_colors.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,           activeIcon: Icons.home_rounded,               label: 'Accueil',      route: RouteNames.home),
    _TabItem(icon: Icons.description_outlined,    activeIcon: Icons.description_rounded,        label: 'Déclarations', route: RouteNames.declarations),
    _TabItem(icon: Icons.compare_arrows_outlined, activeIcon: Icons.compare_arrows_rounded,     label: 'Matchs',       route: RouteNames.matches),
    _TabItem(icon: Icons.chat_bubble_outline,     activeIcon: Icons.chat_bubble_rounded,        label: 'Messages',     route: RouteNames.messaging),
    _TabItem(icon: Icons.person_outline_rounded,  activeIcon: Icons.person_rounded,             label: 'Profil',       route: RouteNames.profile),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith('/${_tabs[i].route}') ||
          location == '/${_tabs[i].route}') return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => context.goNamed(_tabs[i].route),
          items: _tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon),
            activeIcon: Icon(t.activeIcon),
            label: t.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.route});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
}
