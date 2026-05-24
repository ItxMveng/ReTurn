import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../application/auth_notifier.dart';
import '../../application/auth_state.dart';

/// Widget guard : redirige vers login si non authentifié
/// Usage : wraper n’importe quelle page protégée
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    return authState.when(
      initial: () => const _LoadingScreen(),
      checking: () => const _LoadingScreen(),
      loading: () => const _LoadingScreen(),
      authenticated: (_) => child,
      unauthenticated: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.goNamed(RouteNames.login);
        });
        return const _LoadingScreen();
      },
      error: (msg) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.goNamed(RouteNames.login);
        });
        return const _LoadingScreen();
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Provider exposant l’utilisateur courant (non-null si authentifié)
extension AuthNotifierX on WidgetRef {
  bool get isAuthenticated => read(authNotifierProvider) is AuthAuthenticated;
}
