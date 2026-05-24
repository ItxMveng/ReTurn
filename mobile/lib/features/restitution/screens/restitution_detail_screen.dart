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
    final currentUserId = authState.maybeWhen(
      authenticated: (uid, _, __) => uid,
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
            Column(
              children: [
                if (isRequester)
                  _ActionButton(
                    label: 'Marquer comme remis',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    onTap: () async {
                      final ok = await _confirm(
                          context, 'Confirmer la restitution ?',
                          'Le document a bien été remis.');
                      if (!ok) return;
                      await ref
                          .read(restitutionListProvider.notifier)
                          .complete(restitutionId);
                      if (context.mounted) {
                        ref.invalidate(restitutionDetailProvider(restitutionId));
                        context.pop();
                      }
                    },
                  ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'Annuler',
                  icon: Icons.cancel_outlined,
                  color: cs.error,
                  outlined: true,
                  onTap: () async {
                    final ok = await _confirm(
                        context, 'Annuler la restitution ?',
                        'Cette action est irréversible.');
                    if (!ok) return;
                    await ref
                        .read(restitutionListProvider.notifier)
                        .cancel(restitutionId);
                    if (context.mounted) context.pop();
                  },
                ),
              ],
            ),

          if (canRate) ...
          [
            const SizedBox(height: 12),
            _RatingSection(
              restitutionId: restitutionId,
              ref: ref,
            ),
          ],

          if (restitution.isCompleted && !restitution.isDisputed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _ActionButton(
                label: 'Signaler un litige',
                icon: Icons.report_problem_outlined,
                color: Colors.orange,
                outlined: true,
                onTap: () async {
                  final reason = await _promptReason(context);
                  if (reason == null) return;
                  await ref
                      .read(restitutionListProvider.notifier)
                      .dispute(restitutionId, reason: reason);
                  if (context.mounted) {
                    ref.invalidate(restitutionDetailProvider(restitutionId));
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

// ── Widgets helpers ──────────────────────────────────────────────────────────────
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 15)),
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
                  color: cs.onSurface.withValues(alpha: 0.5), fontSize: 13)),
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
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: color),
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
        icon: Icon(icon),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1.0),
                child: Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 40,
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
                      await widget.ref
                          .read(restitutionListProvider.notifier)
                          .rate(widget.restitutionId, _rating);
                      widget.ref.invalidate(
                          restitutionDetailProvider(widget.restitutionId));
                      setState(() => _loading = false);
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
