import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../../features/declarations/presentation/pages/declarations_list_page.dart';
import '../../features/declarations/presentation/pages/declaration_form_page.dart';
import '../../features/declarations/presentation/pages/declaration_detail_page.dart';
import '../../features/matches/presentation/pages/matches_list_page.dart';
import '../../features/matches/presentation/pages/match_detail_page.dart';
import '../../features/matches/presentation/pages/restitution_detail_page.dart';
import '../../features/messaging/presentation/pages/messaging_list_page.dart';
import '../../features/messaging/presentation/pages/conversation_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
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
      // ── Splash ──
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (_, __) => const _SplashPage(),
      ),

      // ── Auth ──
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

      // ── App principale (shell avec bottom nav) ──
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            builder: (_, __) => const HomePage(),
          ),
          GoRoute(
            path: '/declarations',
            name: RouteNames.declarations,
            builder: (_, __) => const DeclarationsListPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: RouteNames.newDeclaration,
                builder: (_, __) => const DeclarationFormPage(),
              ),
              GoRoute(
                path: ':id',
                name: RouteNames.declarationDetail,
                builder: (_, state) => DeclarationDetailPage(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/matches',
            name: RouteNames.matches,
            builder: (_, __) => const MatchesListPage(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.matchDetail,
                builder: (_, state) => MatchDetailPage(
                  id: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/restitutions/:id',
            name: RouteNames.restitutionDetail,
            builder: (_, state) => RestitutionDetailPage(
              id: state.pathParameters['id']!,
            ),
          ),
          // ✅ Messagerie — vraies pages
          GoRoute(
            path: '/messaging',
            name: RouteNames.messaging,
            builder: (_, __) => const MessagingListPage(),
            routes: [
              GoRoute(
                path: ':matchId',
                name: RouteNames.conversation,
                builder: (_, state) => ConversationPage(
                  matchId: state.pathParameters['matchId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (_, __) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'edit',
                name: RouteNames.editProfile,
                builder: (_, __) => const _PlaceholderPage(title: 'Modifier le profil'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String? _redirect(AuthState authState, String location) {
  const publicRoutes = ['/login', '/register', '/otp-verify', '/splash'];
  final isPublic = publicRoutes.any((r) => location.startsWith(r));
  return authState.when(
    initial: () => null, checking: () => null, loading: () => null,
    authenticated: (_) => isPublic ? '/home' : null,
    unauthenticated: () => isPublic ? null : '/login',
    error: (_) => isPublic ? null : '/login',
  );
}

class _SplashPage extends ConsumerWidget {
  const _SplashPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    authState.whenOrNull(
      authenticated: (_) => Future.microtask(() => context.goNamed(RouteNames.home)),
      unauthenticated: () => Future.microtask(() => context.goNamed(RouteNames.login)),
    );
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 48, color: Colors.amber),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Page en cours de développement', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
