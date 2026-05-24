import 'package:flutter/material.dart';
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
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final loggedIn =
        await ref.read(authStorageProvider).isLoggedIn;
    if (!mounted) return;
    context.go(loggedIn ? '/declarations' : '/login');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.find_in_page_rounded,
                    size: 52, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('ReTurn',
                  style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                      color: Colors.white,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Retrouver. Restituer. Confiance.',
                  style: TextStyle(
                      fontFamily: 'Satoshi',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.75))),
            ],
          ),
        ),
      ),
    );
  }
}
