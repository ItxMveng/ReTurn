import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/features/splash/splash_screen.dart';
import 'package:docretour/features/auth/screens/onboarding_screen.dart';
import 'package:docretour/features/auth/presentation/screens/phone_input_screen.dart';
import 'package:docretour/features/auth/presentation/screens/otp_verify_screen.dart';
import 'package:docretour/features/profile/screens/profile_setup_screen.dart';
import 'package:docretour/features/home/screens/home_screen.dart';
import 'package:docretour/features/settings/settings_screen.dart';
import 'package:docretour/features/support/support_screen.dart';
import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';
import 'package:docretour/features/profile/providers/profile_provider.dart';
import 'package:docretour/features/declarations/screens/declarations_list_screen.dart';
import 'package:docretour/features/declarations/screens/declaration_form_screen.dart';
import 'package:docretour/features/declarations/screens/declaration_detail_screen.dart';
import 'package:docretour/features/matching/screens/matches_list_screen.dart';
import 'package:docretour/features/matching/screens/match_detail_screen.dart';
import 'package:docretour/features/messaging/screens/chat_screen.dart';
import 'package:docretour/features/messaging/screens/identity_verification_screen.dart';
import 'package:docretour/features/restitution/screens/restitutions_list_screen.dart';
import 'package:docretour/features/restitution/screens/restitution_detail_screen.dart';

// ── Transition helpers ──────────────────────────────────────────────────────

/// Slide depuis la droite (push standard)
Page<T> _slidePage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5),
        ),
      );
      final secondarySlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.15, 0.0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(
        position: secondarySlide,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(opacity: fade, child: child),
        ),
      );
    },
  );
}

/// Fade simple (pour root tabs / home)
Page<T> _fadePage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}

/// Slide depuis le bas (modales légères)
Page<T> _bottomSlidePage<T>(Widget child, GoRouterState state) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInQuart,
      ));
      return SlideTransition(position: slide, child: child);
    },
  );
}

// ── Router ──────────────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final profileValue = isAuthenticated ? ref.watch(profileProvider) : null;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;

      final isAuthRoute = loc.startsWith('/auth') || loc == '/onboarding';
      final isProfileSetup = loc == '/profile/setup';

      if (!isAuthenticated && !isAuthRoute) return '/onboarding';

      if (isAuthenticated && isAuthRoute) {
        if (profileValue == null || profileValue.isLoading) return null;
        final profile = profileValue.valueOrNull;
        if (profile != null && !profile.isProfileComplete) {
          return '/profile/setup';
        }
        return '/home';
      }

      if (isAuthenticated && !isAuthRoute && !isProfileSetup) {
        if (profileValue == null || profileValue.isLoading) return null;
        final profile = profileValue.valueOrNull;
        if (profile != null && !profile.isProfileComplete) {
          return '/profile/setup';
        }
      }

      return null;
    },
    routes: [
      // ── Auth & onboarding
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => _fadePage(const SplashScreen(), state),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, state) => _fadePage(const OnboardingScreen(), state),
      ),
      GoRoute(
        path: '/auth/phone',
        pageBuilder: (_, state) => _slidePage(const PhoneInputScreen(), state),
      ),
      GoRoute(
        path: '/auth/otp',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _slidePage(
            OtpVerifyScreen(
              verificationId: extra['verificationId'] as String,
              phoneNumber: extra['phoneNumber'] as String,
            ),
            state,
          );
        },
      ),

      // ── Core
      GoRoute(
        path: '/profile/setup',
        pageBuilder: (_, state) =>
            _bottomSlidePage(const ProfileSetupScreen(), state),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (_, state) => _fadePage(const HomeScreen(), state),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _slidePage(const SettingsScreen(), state),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (_, state) => _slidePage(const SupportScreen(), state),
      ),

      // ── Déclarations
      GoRoute(
        path: '/declarations',
        pageBuilder: (_, state) =>
            _slidePage(const DeclarationsListScreen(), state),
      ),
      GoRoute(
        path: '/declarations/new/:type',
        pageBuilder: (_, state) => _bottomSlidePage(
          DeclarationFormScreen(
            declarationType: state.pathParameters['type']!,
          ),
          state,
        ),
      ),
      GoRoute(
        path: '/declarations/:id',
        pageBuilder: (_, state) => _slidePage(
          DeclarationDetailScreen(
            declarationId: state.pathParameters['id']!,
          ),
          state,
        ),
      ),

      // ── Matching
      GoRoute(
        path: '/matches',
        pageBuilder: (_, state) =>
            _slidePage(const MatchesListScreen(), state),
      ),
      GoRoute(
        path: '/matches/:id',
        pageBuilder: (_, state) => _slidePage(
          MatchDetailScreen(matchId: state.pathParameters['id']!),
          state,
        ),
      ),

      // ── Messagerie
      GoRoute(
        path: '/matches/:id/chat',
        pageBuilder: (_, state) => _slidePage(
          ChatScreen(
            matchId: state.pathParameters['id']!,
            title: state.extra as String? ?? 'Chat',
          ),
          state,
        ),
      ),
      GoRoute(
        path: '/matches/:id/verify',
        pageBuilder: (_, state) => _bottomSlidePage(
          IdentityVerificationScreen(
            matchId: state.pathParameters['id']!,
          ),
          state,
        ),
      ),

      // ── Restitutions
      GoRoute(
        path: '/restitutions',
        pageBuilder: (_, state) =>
            _slidePage(const RestitutionsListScreen(), state),
      ),
      GoRoute(
        path: '/restitutions/:id',
        pageBuilder: (_, state) => _slidePage(
          RestitutionDetailScreen(
            restitutionId: state.pathParameters['id']!,
          ),
          state,
        ),
      ),
    ],
  );
});
