import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class RestitutionPage extends ConsumerStatefulWidget {
  final String matchId;
  const RestitutionPage({super.key, required this.matchId});

  @override
  ConsumerState<RestitutionPage> createState() => _RestitutionPageState();
}

class _RestitutionPageState extends ConsumerState<RestitutionPage> {
  int _step = 0; // 0: intro, 1: code, 2: rating, 3: done
  final _codeCtrl = TextEditingController();
  int _rating = 0;
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);

  Future<void> _confirm() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: API call
    setState(() {
      _loading = false;
      _step = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restitution'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepIntro(
            matchId: widget.matchId, onContinue: _next);
      case 1:
        return _StepCode(
            controller: _codeCtrl,
            loading: _loading,
            onConfirm: _confirm);
      case 2:
        return _StepRating(
            rating: _rating,
            onRate: (r) => setState(() => _rating = r),
            onSubmit: _next);
      default:
        return _StepDone(onHome: () => context.go('/declarations'));
    }
  }
}

class _StepIntro extends StatelessWidget {
  final String matchId;
  final VoidCallback onContinue;
  const _StepIntro({required this.matchId, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined,
                    color: AppColors.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Document identifié',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.onSurface)),
                      Text('Match #$matchId',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Comment ça marche ?',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          for (final step in [
            (Icons.qr_code_2, 'Échangez un code de vérification avec l\'autre partie'),
            (Icons.handshake_outlined, 'Remettez le document en main propre'),
            (Icons.star_outline, 'Évaluez la transaction'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(step.$1, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(step.$2,
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurface)),
                  ),
                ],
              ),
            ),
          const Spacer(),
          AppButton(
            label: 'Commencer la restitution',
            expand: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _StepCode extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onConfirm;

  const _StepCode(
      {required this.controller,
      required this.loading,
      required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Code de vérification',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          const Text(
            'Saisissez le code partagé par l\'autre partie',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: AppColors.onSurface),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.outline)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Confirmer la restitution',
            expand: true,
            loading: loading,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _StepRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onRate;
  final VoidCallback onSubmit;

  const _StepRating(
      {required this.rating,
      required this.onRate,
      required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text('Comment s\'est passée\nla restitution ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => onRate(i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    size: 48,
                    color: i < rating
                        ? AppColors.secondary
                        : AppColors.outline,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          AppButton(
            label: 'Valider l\'évaluation',
            expand: true,
            onPressed: rating > 0 ? onSubmit : null,
          ),
        ],
      ),
    );
  }
}

class _StepDone extends StatelessWidget {
  final VoidCallback onHome;
  const _StepDone({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey(3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                size: 80, color: AppColors.success),
            const SizedBox(height: 24),
            const Text('Restitution validée !',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface)),
            const SizedBox(height: 12),
            const Text(
              'Le document a bien été remis. Merci d\'utiliser ReTurn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            AppButton(
                label: 'Retour à l\'accueil',
                expand: true,
                onPressed: onHome),
          ],
        ),
      ),
    );
  }
}
