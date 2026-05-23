import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _subtitleFade;

  bool _minDelayDone = false;
  bool _authResolved = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();

    // Minimum visual delay for the splash to feel intentional
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() => _minDelayDone = true);
      _tryNavigate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryNavigate() {
    if (!_minDelayDone || !_authResolved || !mounted) return;
    final authState = ref.read(authProvider);
    authState.maybeWhen(
      authenticated: (_, __, ___) => context.go('/home'),
      orElse: () => context.go('/onboarding'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    // Listen to auth — navigate as soon as it resolves AND min delay done
    ref.listen(authProvider, (_, next) {
      next.maybeWhen(
        loading: () {}, // still restoring
        orElse: () {
          if (!_authResolved) {
            setState(() => _authResolved = true);
            _tryNavigate();
          }
        },
      );
    });

    // Also watch — if already resolved when screen builds, mark immediately
    final authState = ref.watch(authProvider);
    authState.maybeWhen(
      loading: () {},
      orElse: () {
        if (!_authResolved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_authResolved) {
              setState(() => _authResolved = true);
              _tryNavigate();
            }
          });
        }
      },
    );

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1F16), Color(0xFF0D2B1F), Color(0xFF113524)],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo_ReTurn-removebg.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kGreen.withValues(alpha: 0.15),
                            ),
                            child: const Icon(Icons.find_in_page,
                                size: 80, color: kGreen),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ReTurn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    l.splashTagline,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _subtitleFade,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(active: true),
                        SizedBox(width: 6),
                        _Dot(active: false),
                        SizedBox(width: 6),
                        _Dot(active: false),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: active ? kGreen : Colors.white.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      );
}
