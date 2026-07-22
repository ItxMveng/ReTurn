import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/auth_storage.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});
  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleFade;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _scaleFade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic));
    _subtitleFade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    // En cas d'échec de lecture du stockage sécurisé (keystore, 1er lancement…),
    // on considère l'utilisateur comme non connecté plutôt que de rester figé.
    var loggedIn = false;
    try {
      loggedIn = await ref.read(authStorageProvider).isLoggedIn;
    } catch (e) {
      debugPrint('SplashPage: isLoggedIn failed -> $e');
    }
    if (!mounted) return;
    // Non connecté → onboarding (3 volets, avec « Passer ») puis connexion.
    context.go(loggedIn ? '/declarations' : '/onboarding');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

                // ── Logo + nom ──────────────────────────────────────
                FadeTransition(
                  opacity: _scaleFade,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.75, end: 1.0)
                        .animate(_scaleFade),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo_ReTurn-removebg.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFF01696F).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(Icons.find_in_page_rounded,
                                size: 60, color: Color(0xFF01696F)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ReTurn',
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            fontWeight: FontWeight.w900,
                            fontSize: 40,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Tagline ─────────────────────────────────────────
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'Retrouver. Restituer. Confiance.',
                    style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      letterSpacing: 0.5,
                      color: Colors.white.withOpacity(0.55),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Dots animés ─────────────────────────────────────
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(active: true, anim: _subtitleFade),
                        const SizedBox(width: 6),
                        _Dot(active: false, anim: _subtitleFade),
                        const SizedBox(width: 6),
                        _Dot(active: false, anim: _subtitleFade),
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
  final Animation<double> anim;
  const _Dot({required this.active, required this.anim});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: anim,
        builder: (_, __) => Container(
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF01696F)
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
}
