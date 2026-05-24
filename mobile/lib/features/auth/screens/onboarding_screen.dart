import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/l10n/app_localizations.dart';

// Couleur principale de l'app (teal)
const _kPrimary = Color(0xFF01696F);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/auth/phone');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final l = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    final pages = [
      _PageData(
          icon: Icons.find_in_page_outlined,
          title: l.onboarding1Title,
          body: l.onboarding1Body,
          colorIdx: 0),
      _PageData(
          icon: Icons.search_outlined,
          title: l.onboarding2Title,
          body: l.onboarding2Body,
          colorIdx: 1),
      _PageData(
          icon: Icons.verified_user_outlined,
          title: l.onboarding3Title,
          body: l.onboarding3Body,
          colorIdx: 2),
    ];

    final cardColor =
        Theme.of(context).colorScheme.brightness == Brightness.light
            ? Colors.white
            : Theme.of(context).colorScheme.surfaceContainerHighest;
    final topH = size.height * 0.42;

    return Scaffold(
      body: Stack(
        children: [
          // Fond haut sombre
          Container(
            height: topH,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A1F16), Color(0xFF0D2B1F)],
              ),
            ),
          ),
          // Carte basse
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height - topH + 32,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          // Contenu
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: TextButton(
                      onPressed: () => context.go('/auth/phone'),
                      child: Text(
                        l.onboardingSkip,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                // Logo
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Image.asset(
                      'assets/images/logo_ReTurn-removebg.png',
                      height: 80,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.find_in_page,
                        size: 80,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _OnboardingPage(data: pages[i]),
                  ),
                ),
                // Points de pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 12),
                      width: _page == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i
                            ? _kPrimary
                            : Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Bouton CTA
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      child: Text(_page < pages.length - 1
                          ? l.onboardingNext
                          : l.onboardingStart),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final IconData icon;
  final String title;
  final String body;
  final int colorIdx;
  const _PageData({
    required this.icon,
    required this.title,
    required this.body,
    required this.colorIdx,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _PageData data;
  const _OnboardingPage({required this.data});

  static const _iconColors = [
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
  ];
  static const _iconBgs = [
    Color(0xFFDCFCE7),
    Color(0xFFDBEAFE),
    Color(0xFFFEF3C7),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _iconColors[data.colorIdx % _iconColors.length];
    final bg = _iconBgs[data.colorIdx % _iconBgs.length];
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, -8),
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(data.icon, size: 44, color: color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.6),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
