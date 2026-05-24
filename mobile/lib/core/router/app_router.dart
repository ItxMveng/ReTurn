import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/splash_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/auth/pages/register_page.dart';
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
import '../storage/auth_storage.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStorage = ref.watch(authStorageProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final loggedIn = await authStorage.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';
      if (!loggedIn && !onAuth) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashPage()),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterPage()),
      ShellRoute(
        builder: (c, s, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/declarations',
            builder: (c, s) => const DeclarationsListPage(),
            routes: [
              GoRoute(
                  path: 'new',
                  builder: (c, s) => const DeclarationFormPage()),
              GoRoute(
                  path: ':id',
                  builder: (c, s) =>
                      DeclarationDetailPage(id: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(
            path: '/matches',
            builder: (c, s) => const MatchesListPage(),
            routes: [
              GoRoute(
                  path: ':id',
                  builder: (c, s) =>
                      MatchDetailPage(id: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(
            path: '/messages',
            builder: (c, s) => const ConversationsPage(),
            routes: [
              GoRoute(
                  path: ':roomId',
                  builder: (c, s) =>
                      ChatPage(roomId: s.pathParameters['roomId']!)),
            ],
          ),
          GoRoute(
              path: '/profile',
              builder: (c, s) => const ProfilePage()),
          GoRoute(
              path: '/settings',
              builder: (c, s) => const SettingsPage()),
          GoRoute(
              path: '/restitution/:matchId',
              builder: (c, s) => RestitutionPage(
                  matchId: s.pathParameters['matchId']!)),
        ],
      ),
    ],
  );
});
