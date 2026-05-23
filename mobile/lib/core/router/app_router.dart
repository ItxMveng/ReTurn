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

final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  // Watch profile only when authenticated to avoid unnecessary loading
  final profileValue = isAuthenticated ? ref.watch(profileProvider) : null;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Splash manages its own navigation — never redirect it
      if (loc == '/splash') return null;

      final isAuthRoute = loc.startsWith('/auth') || loc == '/onboarding';
      final isProfileSetup = loc == '/profile/setup';

      // Not authenticated → go to onboarding
      if (!isAuthenticated && !isAuthRoute) return '/onboarding';

      // Authenticated + on auth screen → check profile then go home
      if (isAuthenticated && isAuthRoute) {
        if (profileValue == null || profileValue.isLoading) return null;
        final profile = profileValue.valueOrNull;
        if (profile != null && !profile.isProfileComplete) {
          return '/profile/setup';
        }
        return '/home';
      }

      // Authenticated + not on profile setup → enforce profile completion
      if (isAuthenticated && !isAuthRoute && !isProfileSetup) {
        // Don't block while profile is still loading — let the current screen show
        if (profileValue == null || profileValue.isLoading) return null;
        final profile = profileValue.valueOrNull;
        // Only redirect if we have a definitive answer (profile loaded and incomplete)
        if (profile != null && !profile.isProfileComplete) {
          return '/profile/setup';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',        builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding',    builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/auth/phone',    builder: (_, __) => const PhoneInputScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpVerifyScreen(
            verificationId: extra['verificationId'] as String,
            phoneNumber: extra['phoneNumber'] as String,
          );
        },
      ),
      GoRoute(path: '/profile/setup', builder: (_, __) => const ProfileSetupScreen()),
      GoRoute(path: '/home',          builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/support',       builder: (_, __) => const SupportScreen()),
      GoRoute(path: '/declarations',  builder: (_, __) => const DeclarationsListScreen()),
      GoRoute(
        path: '/declarations/new/:type',
        builder: (_, state) => DeclarationFormScreen(
          declarationType: state.pathParameters['type']!,
        ),
      ),
      GoRoute(
        path: '/declarations/:id',
        builder: (_, state) => DeclarationDetailScreen(
          declarationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/matches',       builder: (_, __) => const MatchesListScreen()),
      GoRoute(
        path: '/matches/:id',
        builder: (_, state) =>
            MatchDetailScreen(matchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/matches/:id/chat',
        builder: (_, state) => ChatScreen(
          matchId: state.pathParameters['id']!,
          title: state.extra as String? ?? 'Chat',
        ),
      ),
      GoRoute(
        path: '/matches/:id/verify',
        builder: (_, state) => IdentityVerificationScreen(
          matchId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
