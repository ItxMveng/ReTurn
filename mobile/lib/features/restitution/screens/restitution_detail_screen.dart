import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:docretour/features/auth/presentation/providers/auth_provider.dart';
import 'package:docretour/features/restitution/providers/restitution_provider.dart';
import 'package:docretour/shared/models/restitution.dart';

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

    // FIX [A]: authenticated(accessToken, refreshToken, userId) — userId est en 3ème position
    final currentUserId = authState.maybeWhen(
      authenticated: (_, __, userId) => userId,
      orElse: () => '',
    );

    final isRequester = restitution.isRequester(currentUserId);
    final canRate = restitution.canRate(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBanner(status: restitution.status),
          const SizedBox(height: 24),
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
            Column(
              children: [
                if (isRequester)
                  _AsyncActionButton(
                    label: 'Marquer comme remis',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onTap: () async {
                      final ok = await _confirm(
                          context, 'Confirmer la restitution ?',
                          'Le document a bien été remis.');
                      if (!ok) return;
                      try {
                        await ref
                            .read(restitutionListProvider.notifier)
                            .complete(restitutionId);
                        if (context.mounted) {
                          ref.invalidate(restitutionDetailProvider(restitutionId));
                          _showSnack(context, '✅ Restitution confirmée !', success: true);
                          context.pop();
                        }
                      } catch (e) {
                        if (context.mounted) _showSnack(context, 'Erreur : $e');
                      }
                    },
                  ),
                const SizedBox(height: 12),
                _AsyncActionButton(
                  label: 'Annuler',
                  icon: Icons.cancel_outlined,
                  color: cs.error,
                  outlined: true,
                  onTap: () async {
                    final ok = await _confirm(
                        context, 'Annuler la restitution ?',
                        'Cette action est irréversible.');
                    if (!ok) return;
                    try {
                      await ref
                          .read(restitutionListProvider.notifier)
                          .cancel(restitutionId);
                      if (context.mounted) {
                        _showSnack(context, 'Restitution annulée.', success: true);
                        context.pop();
                      }
                    } catch (e) {
                      if (context.mounted) _showSnack(context, 'Erreur : $e');
                    }
                  },
                ),
              ],
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
              child: _AsyncActionButton(
                label: 'Signaler un litige',
                icon: Icons.report_problem_outlined,
                color: Colors.orange,
                outlined: true,
                onTap: () async {
                  final reason = await _promptReason(context);
                  if (reason == null || reason.isEmpty) return;
                  try {
                    await ref
                        .read(restitutionListProvider.notifier)
                        .dispute(restitutionId, reason: reason);
                    if (context.mounted) {
                      ref.invalidate(restitutionDetailProvider(restitutionId));
                      _showSnack(context, 'Litige signalé.', success: true);
                    }
                  } catch (e) {
                    if (context.mounted) _showSnack(context, 'Erreur : $e');
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  void _showSnack(BuildContext ctx, String msg, {bool success = false}) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _confirm(BuildContext ctx, String title, String msg) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmer')),
            ],
          ),
        ) ??
        false;
  }

  Future<String?> _promptReason(BuildContext ctx) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Motif du litige'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Décrivez le problème…'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Envoyer')),
        ],
      ),
    );
  }
}

// ── Action button avec loading intégré ──────────────────────────────────────
class _AsyncActionButton extends StatefulWidget {
  const _AsyncActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onTap;
  final bool outlined;

  @override
  State<_AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<_AsyncActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final child = _loading
        ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18),
              const SizedBox(width: 8),
              Text(widget.label),
            ],
          );

    if (widget.outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _loading ? null : _handle,
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.color,
            side: BorderSide(color: widget.color.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _loading ? null : _handle,
        style: FilledButton.styleFrom(
          backgroundColor: widget.color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: child,
      ),
    );
  }

  Future<void> _handle() async {
    setState(() => _loading = true);
    await widget.onTap();
    if (mounted) setState(() => _loading = false);
  }
}

// ── Widgets helpers ──────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = T