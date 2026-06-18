import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:return_mobile/core/theme/app_theme.dart';
import 'package:return_mobile/l10n/app_localizations.dart';

const _tourBoxKey = 'settings';
const _tourSeenKey = 'has_seen_tour';

Future<bool> shouldShowTour() async {
  final box = await Hive.openBox(_tourBoxKey);
  return box.get(_tourSeenKey, defaultValue: false) == false;
}

Future<void> markTourSeen() async {
  final box = await Hive.openBox(_tourBoxKey);
  await box.put(_tourSeenKey, true);
}

/// Réinitialise le flag au logout — prochain login = tour affiché à nouveau.
Future<void> resetTourFlag() async {
  final box = await Hive.openBox(_tourBoxKey);
  await box.put(_tourSeenKey, false);
}

class GuidedTourOverlay extends StatefulWidget {
  final Widget child;
  const GuidedTourOverlay({super.key, required this.child});

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  int _step = 0;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final show = await shouldShowTour();
      if (show && mounted) {
        setState(() => _visible = true);
        _anim.forward();
      }
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final l = AppLocalizations.of(context);
    final steps = _buildSteps(l);
    if (_step < steps.length - 1) {
      await _anim.reverse();
      if (mounted) {
        setState(() => _step++);
        _anim.forward();
      }
    } else {
      await _dismiss();
    }
  }

  Future<void> _dismiss() async {
    await _anim.reverse();
    await markTourSeen();
    if (mounted) setState(() => _visible = false);
  }

  List<_TourStep> _buildSteps(AppLocalizations l) => [
        _TourStep(
          icon: Icons.celebration,
          title: l.tourStep1Title,
          body: l.tourStep1Body,
        ),
        _TourStep(
          icon: Icons.description_outlined,
          title: l.tourStep2Title,
          body: l.tourStep2Body,
        ),
        _TourStep(
          icon: Icons.compare_arrows,
          title: l.tourStep3Title,
          body: l.tourStep3Body,
        ),
        _TourStep(
          icon: Icons.chat_bubble_outline,
          title: l.tourStep4Title,
          body: l.tourStep4Body,
        ),
        _TourStep(
          icon: Icons.person_outline,
          title: l.tourStep5Title,
          body: l.tourStep5Body,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;
    final l = AppLocalizations.of(context);
    final steps = _buildSteps(l);
    final step = steps[_step];
    final isLast = _step == steps.length - 1;

    return Stack(
      children: [
        widget.child,
        FadeTransition(
          opacity: _fade,
          child: _TourSheet(
            step: step,
            stepIndex: _step,
            totalSteps: steps.length,
            isLast: isLast,
            onNext: _next,
            onSkip: _dismiss,
            l: l,
          ),
        ),
      ],
    );
  }
}

class _TourSheet extends StatelessWidget {
  final _TourStep step;
  final int stepIndex;
  final int totalSteps;
  final bool isLast;
  final VoidCallback onNext;
  final Future<void> Function() onSkip;
  final AppLocalizations l;

  const _TourSheet({
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.70),
            ],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Green accent bar at top
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Step dots + counter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ...List.generate(
                              totalSteps,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: i == stepIndex ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == stepIndex
                                      ? kGreen
                                      : kGreen.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${stepIndex + 1} / $totalSteps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Icon
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: kGreen.withValues(alpha: 0.40),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child:
                              Icon(step.icon, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Body
                        Text(
                          step.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.65,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Buttons
                        Row(
                          children: [
                            if (!isLast)
                              TextButton(
                                onPressed: onSkip,
                                style: TextButton.styleFrom(
                                  foregroundColor: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.50),
                                ),
                                child: Text(l.tourSkip),
                              ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: onNext,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(130, 46),
                                backgroundColor: kGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                isLast ? l.tourDone : l.tourNext,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourStep {
  final IconData icon;
  final String title;
  final String body;
  const _TourStep({required this.icon, required this.title, required this.body});
}
