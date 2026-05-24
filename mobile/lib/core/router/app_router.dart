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

// ── Transition helpers ────────────────────────────────────────────────────────

/// Slide depuis la droite + fade — utilisé pour toutes les routes "push"
Page<T> _slideTransition<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
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
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ),
      );
      final secondarySlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.2, 0.0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
      ));
      return SlideTransition(
        position: secondarySlide,
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        ),
      );
    },
  );
}

/// Fade seul — pour les modales et overlays (chat, settings)
Page<T> _fadeTransition<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Slide depuis le bas — pour les sheets (form, setup)
Page<T> _bottomSheetTransition<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
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

// ── Router ────────────────────────────────────────────────────────────────────

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
      // ── Auth & onboarding ─────────────────────────────────────────
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => _fadeTransition(state.pageKey, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, state) => _fadeTransition(state.pageKey, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth/phone',
        pageBuilder: (_, state) => _slideTransition(state.pageKey, const PhoneInputScreen()),
      ),
      GoRoute(
        path: '/auth/otp',
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return _slideTransition(
            state.pageKey,
            OtpVerifyScreen(
              verificationId: extra['verificationId'] as String,
              phoneNumber: extra['phoneNumber'] as String,
            ),
          );
        },
      ),

      // ── Core ──────────────────────────────────────────────────────
      GoRoute(
        path: '/profile/setup',
        pageBuilder: (_, state) =>
            _bottomSheetTransition(state.pageKey, const ProfileSetupScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (_, state) => _fadeTransition(state.pageKey, const HomeScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _slideTransition(state.pageKey, const SettingsScreen()),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (_, state) => _slideTransition(state.pageKey, const SupportScreen()),
      ),

      // ── Déclarations ──────────────────────────────────────────────
      GoRoute(
        path: '/declarations',
        pageBuilder: (_, state) =>
            _slideTransition(state.pageKey, const DeclarationsListScreen()),
      ),
      GoRoute(
        path: '/declarations/new/:type',
        pageBuilder: (_, state) => _bottomSheetTransition(
          state.pageKey,
          DeclarationFormScreen(
            declarationType: state.pathParameters['type']!,
          ),
        ),
      ),
      GoRoute(
        path: '/declarations/:id',
        pageBuilder: (_, state) => _slideTransition(
          state.pageKey,
          DeclarationDetailScreen(declarationId: state.pathParameters['id']!),
        ),
      ),

      // ── Matching ──────────────────────────────────────────────────
      GoRoute(
        path: '/matches',
        pageBuilder: (_, state) =>
            _slideTransition(state.pageKey, const MatchesListScreen()),
      ),
      GoRoute(
        path: '/matches/:id',
        pageBuilder: (_, state) => _slideTransition(
          state.pageKey,
          MatchDetailScreen(matchId: state.pathParameters['id']!),
        ),
      ),

      // ── Messagerie ────────────────────────────────────────────────
      GoRoute(
        path: '/matches/:id/chat',
        pageBuilder: (_, state) => _slideTransition(
          state.pageKey,
          ChatScreen(
            matchId: state.pathParameters['id']!,
            title: state.extra as String? ?? 'Chat',
          ),
        ),
      ),
      GoRoute(
        path: '/matches/:id/verify',
        pageBuilder: (_, state) => _bottomSheetTransition(
          state.pageKey,
          IdentityVerificationScreen(matchId: state.pathParameters['id']!),
        ),
      ),

      // ── Restitutions ──────────────────────────────────────────────
      GoRoute(
        path: '/restitutions',
        pageBuilder: (_, state) =>
            _slideTransition(state.pageKey, const RestitutionsListScreen()),
      ),
      GoRoute(
        path: '/restitutions/:id',
        pageBuilder: (_, state) => _slideTransition(
          state.pageKey,
          RestitutionDetailScreen(
            restitutionId: state.pathParameters['id']!,
          ),
        ),
      ),
    ],
  );
});
