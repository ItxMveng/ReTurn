import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:return_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:return_mobile/features/restitution/providers/restitution_provider.dart';
import 'package:return_mobile/shared/models/restitution.dart';

class RestitutionDetailScreen extends ConsumerWidget {
  const RestitutionDetailScreen({super.key, required this.restitutionId});
  final String restitutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(restitutionDetailProvider(restitutionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail restitution'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(restitutionDetailProvider(restitutionId)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (restitution) => _RestitutionDetailBody(
          restitution: restitution,
          restitutionId: restitutionId,
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _RestitutionDetailBody extends ConsumerWidget {
  const _RestitutionDetailBody({
    required this.restitution,
    required this.restitutionId,
  });
  final Restitution restitution;
  final String restitutionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);

    // FIX [A] : ordre correct des paramètres authenticated
    // AuthState.authenticated(accessToken:, refreshToken:, userId:)
    final currentUserId = authState.maybeWhen(
      authenticated: (accessToken, refreshToken, userId) => userId,
      orElse: () => '',
    );

    final isRequester = restitution.isRequester(currentUserId);
    final canRate = restitution.canRate(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          _StatusBanner(status: restitution.status),
          const SizedBox(height: 24),

          // Infos
          _InfoCard(title: 'Rôle', value: isRequester ? 'Demandeur' : 'Détenteur'),
          if (restitution.meetingLocation != null)
            _InfoCard(
                title: 'Lieu de rencontre',
                value: restitution.meetingLocation!),
          if (restitution.meetingScheduledAt != null)
            _InfoCard(
              title: 'Rendez-vous prévu',
              value: _formatDate(restitution.meetingScheduledAt!),
            ),
          if (restitution.completedAt != null)
            _InfoCard(
              title: 'Complétée le',
              value: _formatDate(restitution.completedAt!),
            ),
          if (restitution.holderRating != null)
            _InfoCard(
              title: 'Note détenteur',
              value: '★ ${restitution.holderRating!.toStringAsFixed(1)} / 5',
            ),
          if (restitution.requesterRating != null)
            _InfoCard(
              title: 'Note demandeur',
              value: '★ ${restitution.requesterRating!.toStringAsFixed(1)} / 5',
            ),

          const SizedBox(height: 32),

          // Actions
          if (restitution.isActive)
            _ActiveActions(
              isRequester: isRequester,
              restitutionId: restitutionId,
            ),

          if (canRate) ...[
            const SizedBox(height: 12),
            _RatingSection(
              restitutionId: restitutionId,
              ref: ref,
            ),
          ],

          if (restitution.isCompleted && !restitution.isDisputed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _DisputeButton(
                restitutionId: restitutionId,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ── Active actions (complete + cancel) ────────────────────────────────────────

class _ActiveActions extends ConsumerStatefulWidget {
  const _ActiveActions({
    required this.isRequester,
    required this.restitutionId,
  });
  final bool isRequester;
  final String restitutionId;

  @override
  ConsumerState<_ActiveActions> createState() => _ActiveActionsState();
}

class _ActiveActionsState extends ConsumerState<_ActiveActions> {
  bool _loadingComplete = false;
  bool _loadingCancel = false;

  void _snack(String msg, {Color? color, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 10)],
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color ?? Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _complete() async {
    final ok = await _confirm('Confirmer la restitution ?',
        'Le document a bien été remis au propriétaire.');
    if (!ok) return;
    setState(() => _loadingComplete = true);
    try {
      await ref
          .read(restitutionListProvider.notifier)
          .complete(widget.restitutionId);
      ref.invalidate(restitutionDetailProvider(widget.restitutionId));
      _snack('Restitution complétée ✅',
          color: Colors.green, icon: Icons.check_circle);
      if (mounted) context.pop();
    } catch (e) {
      _snack('Erreur : ${e.toString()}',
          color: Theme.of(context).colorScheme.error,
          icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _loadingComplete = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await _confirm(
        'Annuler la restitution ?', 'Cette action est irréversible.');
    if (!ok) return;
    setState(() => _loadingCancel = true);
    try {
      await ref
          .read(restitutionListProvider.notifier)
          .cancel(widget.restitutionId);
      _snack('Restitution annulée', icon: Icons.cancel);
      if (mounted) context.pop();
    } catch (e) {
      _snack('Erreur : ${e.toString()}',
          color: Theme.of(context).colorScheme.error,
          icon: Icons.error_outline);
    } finally {
      if (mounted) setState(() => _loadingCancel = false);
    }
  }

  Future<bool> _confirm(String title, String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirmer')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (widget.isRequester)
          _ActionButton(
            label: 'Marquer comme remis',
            icon: Icons.check_circle_outline,
            color: Colors.green,
            loading: _loadingComplete,
            onTap: _loadingComplete || _loadingCancel ? null : _complete,
          ),
        const SizedBox(height: 12),
        _ActionButton(
          label: 'Annuler',
          icon: Icons.cancel_outlined,
          color: cs.error,
          outlined: true,
          loading: _loadingCancel,
          onTap: _loadingComplete || _loadingCancel ? null : _cancel,
        ),
      ],
    );
  }
}

// ── Dispute button ─────────────────────────────────────────────────────────────

class _DisputeButton extends ConsumerStatefulWidget {
  const _DisputeButton({required this.restitutionId});
  final String restitutionId;

  @override
  ConsumerState<_DisputeButton> createState() => _DisputeButtonState();
}

class _DisputeButtonState extends ConsumerState<_DisputeButton> {
  bool _loading = false;

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _ActionButton(
      label: 'Signaler un litige',
      icon: Icons.report_problem_outlined,
      color: Colors.orange,
      outlined: true,
      loading: _loading,
      onTap: _loading
          ? null
          : () async {
              final reason = await _promptReason();
              if (reason == null || reason.isEmpty) return;
              setState(() => _loading = true);
              try {
                await ref
                    .read(restitutionListProvider.notifier)
                    .dispute(widget.restitutionId, reason: reason);
                ref.invalidate(
                    restitutionDetailProvider(widget.restitutionId));
                _snack('Litige signalé — notre équipe vous contactera',
                    color: Colors.orange);
              } catch (e) {
                _snack('Erreur : ${e.toString()}',
                    color: cs.error);
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
    );
  }

  Future<String?> _promptReason() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motif du litige'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Décrivez le problème…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Envoyer')),
        ],
      ),
    );
  }
}

// ── Widgets helpers ──────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (status) {
      'requested' => cs.primary,
      'verified'  => Colors.orange,
      'completed' => Colors.green,
      'disputed'  => cs.error,
      'cancelled' => cs.onSurface.withValues(alpha: 0.4),
      _           => cs.outline,
    };
    final label = switch (status) {
      'requested' => 'Restitution demandée',
      'verified'  => 'Identité vérifiée — en attente de remise',
      'completed' => 'Restitution complétée ✅',
      'disputed'  => 'Litige en cours',
      'cancelled' => 'Annulée',
      _           => status,
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) =>
          Opacity(opacity: v, child: Transform.translate(
            offset: Offset(0, 12 * (1 - v)),
            child: child,
          )),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$title : ',
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.5),
                  fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.loading = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool outlined;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final iconWidget = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? color : Colors.white,
            ),
          )
        : Icon(icon, color: outlined ? color : null);

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: iconWidget,
          label: Text(label, style: TextStyle(color: color)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: iconWidget,
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _RatingSection extends StatefulWidget {
  const _RatingSection({required this.restitutionId, required this.ref});
  final String restitutionId;
  final WidgetRef ref;

  @override
  State<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends State<_RatingSection> {
  double _rating = 4;
  bool _loading = false;
  bool _submitted = false;

  void _snack(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('Note envoyée — merci !',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Noter cette restitution',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1.0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    i < _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    key: ValueKey('$i-${i < _rating}'),
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      try {
                        await widget.ref
                            .read(restitutionListProvider.notifier)
                            .rate(widget.restitutionId, _rating);
                        widget.ref.invalidate(
                            restitutionDetailProvider(
                                widget.restitutionId));
                        setState(() {
                          _loading = false;
                          _submitted = true;
                        });
                        _snack(
                          '⭐ Note de ${_rating.toInt()}/5 envoyée, merci !',
                          color: Colors.green,
                        );
                      } catch (e) {
                        setState(() => _loading = false);
                        _snack('Erreur : ${e.toString()}',
                            color: cs.error);
                      }
                    },
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer la note'),
            ),
          ),
        ],
      ),
    );
  }
}
