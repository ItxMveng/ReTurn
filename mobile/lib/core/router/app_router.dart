import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/declarations/providers/declarations_provider.dart';
import '../../features/matches/providers/matches_provider.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../../features/splash/splash_page.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/declarations/pages/declarations_list_page.dart';
import '../../features/declarations/pages/declaration_form_page.dart';
import '../../features/declarations/pages/declaration_detail_page.dart';
import '../../features/declarations/pages/multi_doc_declaration_page.dart';
import '../../features/matches/pages/matches_list_page.dart';
import '../../features/matches/pages/match_detail_page.dart';
import '../../features/messaging/pages/conversations_page.dart';
import '../../features/messaging/pages/chat_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/restitution/pages/restitution_page.dart';
import '../../features/restitution/pages/restitutions_history_page.dart';
import '../../features/verification/pages/verification_page.dart';
import '../../features/zones/pages/zones_page.dart';
import '../../features/info/pages/info_pages.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/ocr/pages/ocr_scan_page.dart';
import '../../features/ocr/pages/ocr_review_page.dart';

/// Alias public utilisé dans main.dart
final appRouterProvider = routerProvider;

final routerProvider = Provider<GoRouter>((ref) {
  // Réévalue les redirections quand l'état d'auth change (session expirée,
  // logout forcé par l'intercepteur réseau, etc.).
  final refresh = ValueNotifier(0);
  ref.listen(authNotifierProvider, (prev, next) {
    refresh.value++;
    // À la connexion, on force un refetch propre des données : évite qu'un
    // fetch déclenché trop tôt (token pas encore prêt) laisse une erreur en
    // cache et oblige l'utilisateur à recharger la page plusieurs fois.
    if (next is AuthAuthenticated && prev is! AuthAuthenticated) {
      ref.invalidate(profileProvider);
      ref.invalidate(declarationsProvider);
      ref.invalidate(matchesProvider);
    }
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;
      final isPublic = loc.startsWith('/auth') ||
          loc == '/splash' ||
          loc == '/onboarding' ||
          loc == '/help' ||
          loc == '/privacy';
      final isLoggedOut = auth is AuthUnauthenticated;
      if (isLoggedOut && !isPublic) return '/auth/phone';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneInputScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) =>
            OtpVerifyScreen(phoneNumber: state.extra as String),
      ),

      // ── OCR (hors shell — plein écran) ─────────────────────────
      GoRoute(path: '/ocr/scan', builder: (_, __) => const OcrScanPage()),
      GoRoute(path: '/ocr/review', builder: (_, __) => const OcrReviewPage()),

      // ── Déclaration multi-documents (tri auto — plein écran) ────
      GoRoute(
          path: '/declarations/multi',
          builder: (_, __) => const MultiDocDeclarationPage()),

      // ── Shell avec NavigationBar ────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/declarations',
            builder: (_, __) => const DeclarationsListPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, state) => DeclarationFormPage(
                  declarationType: state.uri.queryParameters['type'] ?? 'found',
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    DeclarationDetailPage(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/matches',
            builder: (_, __) => const MatchesListPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    MatchDetailPage(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/messages',
            builder: (_, __) => const ConversationsPage(),
            routes: [
              GoRoute(
                path: ':roomId',
                builder: (_, state) {
                  final extra = state.extra as (String?, String?)?;
                  return ChatPage(
                    roomId: state.pathParameters['roomId']!,
                    otherName: extra?.$1,
                    otherAvatar: extra?.$2,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfilePage(),
          ),
        ],
      ),

      GoRoute(
        path: '/restitution/:matchId',
        builder: (_, state) =>
            RestitutionPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
        path: '/verify/:matchId',
        builder: (_, state) =>
            VerificationPage(matchId: state.pathParameters['matchId']!),
      ),
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsPage()),
      GoRoute(
          path: '/restitutions',
          builder: (_, __) => const RestitutionsHistoryPage()),
      GoRoute(path: '/zones', builder: (_, __) => const ZonesPage()),
      GoRoute(path: '/help', builder: (_, __) => const HelpPage()),
      GoRoute(path: '/support', builder: (_, __) => const SupportPage()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyPage()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    ],
  );
});
