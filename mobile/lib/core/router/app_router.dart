import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../widgets/scaffold_with_nav_bar.dart';
import 'route_names.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/splash',
    redirect: (context, state) => _redirect(authState, state.matchedLocation),
    routes: [
      // ── Splash ───────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, __) => const _SplashPage(),
      ),

      // ── Auth ─────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (_, __) => const RegisterPage(),
      ),
      GoRoute(
        path: '/otp-verify',
        name: RouteNames.otpVerify,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerifyPage(phoneNumber: phone);
        },
      ),

      // ── App principale (shell avec bottom nav) ────────────────
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            builder: (_, __) => const _PlaceholderPage(title: 'Accueil'),
          ),
          GoRoute(
            path: '/declarations',
            name: RouteNames.declarations,
            builder: (_, __) => const _PlaceholderPage(title: 'Déclarations'),
            routes: [
              GoRoute(
                path: 'new',
                name: RouteNames.newDeclaration,
                builder: (_, __) => const _PlaceholderPage(title: 'Nouvelle déclaration'),
              ),
            ],
          ),
          GoRoute(
            path: '/matches',
            name: RouteNames.matches,
            builder: (_, __) => const _PlaceholderPage(title: 'Correspondances'),
          ),
          GoRoute(
            path: '/messaging',
            name: RouteNames.messaging,
            builder: (_, __) => const _PlaceholderPage(title: 'Messagerie'),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (_, __) => const _PlaceholderPage(title: 'Profil'),
          ),
        ],
      ),
    ],
  );
}

/// Logique de redirection centralisée
String? _redirect(AuthState authState, String location) {
  final publicRoutes = ['/login', '/register', '/otp-verify', '/splash'];
  final isPublic = publicRoutes.any((r) => location.startsWith(r));

  return authState.when(
    initial: () => null,
    checking: () => null,
    loading: () => null,
    authenticated: (_) => isPublic ? '/home' : null,
    unauthenticated: () => isPublic ? null : '/login',
    error: (_) => isPublic ? null : '/login',
  );
}

/// Page splash simple — affiche un indicateur pendant la vérif auth
class _SplashPage extends ConsumerWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    authState.whenOrNull(
      authenticated: (_) => Future.microtask(() => context.goNamed(RouteNames.home)),
      unauthenticated: () => Future.microtask(() => context.goNamed(RouteNames.login)),
    );
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Placeholder pour les pages non encore implémentées
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
    );
  }
}
