import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_colors.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)),
    );
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final storage = ref.read(secureStorageProvider);
    final isAuth = await storage.isAuthenticated();
    if (!mounted) return;
    context.goNamed(isAuth ? RouteNames.home : RouteNames.login);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo SVG inline
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.onPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.find_in_page_rounded, size: 56, color: AppColors.onPrimary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ReTurn',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Retrouvez vos documents perdus',
                  style: TextStyle(
                    color: AppColors.onPrimary.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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
