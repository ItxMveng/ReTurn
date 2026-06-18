import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/matches_notifier.dart';
import '../../data/models/match_model.dart';
import '../../declarations/application/declarations_notifier.dart';

class MatchDetailPage extends ConsumerWidget {
  const MatchDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMatch = ref.watch(matchDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Détail du match')),
      body: asyncMatch.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.error))),
        data: (match) => _MatchBody(match: match),
      ),
    );
  }
}

class _MatchBody extends ConsumerWidget {
  const _MatchBody({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncFound = ref.watch(declarationDetailProvider(match.foundDeclarationId));
    final asyncLost  = ref.watch(declarationDetailProvider(match.lostDeclarationId));
    final found = asyncFound.valueOrNull;
    final lost  = asyncLost.valueOrNull;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─ Score ─
        _ScoreBanner(score: match.scorePercent.toInt()),
        const SizedBox(height: 20),

        // ─ Les deux déclarations ─
        if (found != null || lost != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (found != null) Expanded(child: _DeclMini(
                label: 'Trouvé',
                color: AppColors.success,
                docType: found.documentLabel,
                ownerName: found.ownerName,
                location: found.locationDescription,
              )),
              const SizedBox(width: 12),
              if (lost != null) Expanded(child: _DeclMini(
                label: 'Perdu',
                color: AppColors.error,
                docType: lost.documentLabel,
                ownerName: lost.ownerName,
                location: lost.locationDescription,
              )),
            ],
          ),
        const SizedBox(height: 24),

        // ─ Statut confirmation ─
        _ConfirmStatus(match: match),
        const SizedBox(height: 24),

        // ─ Actions (si pending) ─
        if (match.isPending) ..._buildActions(context, ref),

        // ─ Lien restitution (si confirmed + restitutionId) ─
        if (match.isConfirmed && match.restitutionId != null) ...[
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.pushNamed('restitution-detail', pathParameters: {'id': match.restitutionId!}),
            icon: const Icon(Icons.handshake_rounded),
            label: const Text('Voir la restitution'),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref) {
    return [
      ElevatedButton.icon(
        onPressed: () => _act(context, ref, 'confirmed'),
        icon: const Icon(Icons.check_circle_rounded),
        label: const Text('Confirmer ce match'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => _act(context, ref, 'ignored'),
        icon: const Icon(Icons.cancel_rounded, color: AppColors.error),
        label: const Text('Ignorer', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
      ),
    ];
  }

  Future<void> _act(BuildContext context, WidgetRef ref, String action) async {
    final response = await ref.read(matchesNotifierProvider.notifier).actOnMatch(match.id, action);
    if (!context.mounted) return;
    if (response != null && response.bothConfirmed && response.restitutionId != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Les deux parties ont confirmé ! La restitution est créée.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.pushNamed('restitution-detail', pathParameters: {'id': response.restitutionId!});
    } else if (action == 'confirmed') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('En attente de confirmation de l’autre partie.'),
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } else {
      context.pop();
    }
  }
}

class _ScoreBanner extends StatelessWidget {
  const _ScoreBanner({required this.score});
  final int score;

  Color get _color {
    if (score >= 80) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Text('Score de correspondance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('$score%', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: _color)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: _color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclMini extends StatelessWidget {
  const _DeclMini({required this.label, required this.color, required this.docType, this.ownerName, this.location});
  final String label;
  final Color color;
  final String docType;
  final String? ownerName;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 8),
          Text(docType, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          if (ownerName != null) ...[const SizedBox(height: 4), Text(ownerName!, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis)],
          if (location  != null) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: AppColors.onSurfaceVariant), const SizedBox(width: 2), Expanded(child: Text(location!, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis))])],
        ],
      ),
    );
  }
}

class _ConfirmStatus extends StatelessWidget {
  const _ConfirmStatus({required this.match});
  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirmations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 12),
          _ConfirmRow(label: 'Propriétaire', confirmed: match.confirmedByOwner),
          const SizedBox(height: 8),
          _ConfirmRow(label: 'Trouveur',     confirmed: match.confirmedByFinder),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.confirmed});
  final String label;
  final bool? confirmed;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = confirmed ?? false;
    return Row(
      children: [
        Icon(isConfirmed ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 18, color: isConfirmed ? AppColors.success : AppColors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: isConfirmed ? AppColors.onSurface : AppColors.onSurfaceVariant, fontWeight: isConfirmed ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}
