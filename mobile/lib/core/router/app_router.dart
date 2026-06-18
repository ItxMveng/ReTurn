import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/splash_page.dart';
import '../../features/auth/screens/phone_input_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/declarations/pages/declarations_list_page.dart';
import '../../features/declarations/pages/declaration_form_page.dart';
import '../../features/declarations/pages/declaration_detail_page.dart';
import '../../features/matches/pages/matches_list_page.dart';
import '../../features/matches/pages/match_detail_page.dart';
import '../../features/messaging/pages/conversations_page.dart';
import '../../features/messaging/pages/chat_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/restitution/pages/restitution_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/ocr/pages/ocr_scan_page.dart';
import '../../features/ocr/pages/ocr_review_page.dart';

/// Alias public utilisé dans main.dart
final appRouterProvider = routerProvider;

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
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
                builder: (_, state) =>
                    ChatPage(roomId: state.pathParameters['roomId']!),
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
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
    ],
  );
});
