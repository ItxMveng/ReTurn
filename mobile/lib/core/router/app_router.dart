import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../storage/secure_storage.dart';
import 'route_names.dart';

// Imports temporaires — les vraies pages seront ajoutées dans les prochains commits
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../shared/widgets/scaffold_shell.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final storage = ref.watch(secureStorageProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final isAuth = await storage.isAuthenticated();
      final loc = state.matchedLocation;

      final authRoutes = [RoutePaths.login, RoutePaths.register, RoutePaths.otpVerify, RoutePaths.onboarding, RoutePaths.splash];
      final isAuthRoute = authRoutes.contains(loc);

      if (!isAuth && !isAuthRoute) return RoutePaths.login;
      if (isAuth && isAuthRoute && loc != RoutePaths.splash) return RoutePaths.home;
      return null;
    },
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (_, __) => const SplashPage(),
      ),

      // ── Auth ───────────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (_, state) => _fadeTransition(state, const LoginPage()),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        pageBuilder: (_, state) => _fadeTransition(state, const RegisterPage()),
      ),

      // ── Shell avec BottomNavigation ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => ScaffoldShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: RoutePaths.declarations,
            name: RouteNames.declarations,
            builder: (_, __) => const PlaceholderPage(title: 'Déclarations'),
          ),
          GoRoute(
            path: RoutePaths.matches,
            name: RouteNames.matches,
            builder: (_, __) => const PlaceholderPage(title: 'Correspondances'),
          ),
          GoRoute(
            path: RoutePaths.messages,
            name: RouteNames.messages,
            builder: (_, __) => const PlaceholderPage(title: 'Messagerie'),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (_, __) => const PlaceholderPage(title: 'Profil'),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page introuvable : ${state.error}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ),
  );
}

CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Page temporaire pour les routes non encore implémentées
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('En cours de développement', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
