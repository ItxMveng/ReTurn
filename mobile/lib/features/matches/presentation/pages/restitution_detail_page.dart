import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/matches_notifier.dart';
import '../../data/repositories/matches_repository.dart';
import '../../../restitution/data/models/restitution_model.dart';

class RestitutionDetailPage extends ConsumerStatefulWidget {
  const RestitutionDetailPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<RestitutionDetailPage> createState() => _RestitutionDetailPageState();
}

class _RestitutionDetailPageState extends ConsumerState<RestitutionDetailPage> {
  int? _selectedRating;
  bool _ratingSubmitted = false;
  bool _submittingRating = false;
  final _meetingCtrl = TextEditingController();
  bool _updatingMeeting = false;

  @override
  void dispose() {
    _meetingCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitRating(RestitutionModel rest) async {
    if (_selectedRating == null) return;
    setState(() => _submittingRating = true);
    try {
      await ref.read(matchesRepositoryProvider).rateRestitution(rest.id, _selectedRating!);
      if (mounted) setState(() { _ratingSubmitted = true; _submittingRating = false; });
      ref.invalidate(restitutionDetailProvider(widget.id));
    } catch (e) {
      if (mounted) {
        setState(() => _submittingRating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _saveMeetingPoint(String id) async {
    if (_meetingCtrl.text.trim().isEmpty) return;
    setState(() => _updatingMeeting = true);
    try {
      await ref.read(matchesRepositoryProvider).updateRestitution(id, meetingPoint: _meetingCtrl.text.trim());
      ref.invalidate(restitutionDetailProvider(widget.id));
      if (mounted) {
        setState(() => _updatingMeeting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Lieu de rendez-vous enregistré'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) setState(() => _updatingMeeting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRest = ref.watch(restitutionDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Restitution')),
      body: asyncRest.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppColors.error))),
        data: (rest) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─ Statut ─
            _StatusBanner(rest: rest),
            const SizedBox(height: 20),

            // ─ Lieu de rendez-vous ─
            const _SectionTitle(title: 'Lieu de remise'),
            const SizedBox(height: 10),
            rest.meetingPoint != null
                ? _InfoBox(value: rest.meetingPoint!)
                : Column(
                    children: [
                      TextField(
                        controller: _meetingCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ex : Devant la mairie de Douala',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _updatingMeeting ? null : () => _saveMeetingPoint(rest.id),
                        child: _updatingMeeting
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Enregistrer le lieu'),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),

            // ─ Photos de preuve ─
            if (rest.proofPhotoUrls.isNotEmpty) ...[
              const _SectionTitle(title: 'Photos de preuve'),
              const SizedBox(height: 10),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: rest.proofPhotoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(rest.proofPhotoUrls[i], width: 180, height: 140, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─ Notation (si completed) ─
            if (rest.isCompleted && !_ratingSubmitted) ...[
              const _SectionTitle(title: 'Notez cette restitution'),
              const SizedBox(height: 10),
              _StarRating(
                rating: _selectedRating ?? 0,
                onChanged: (r) => setState(() => _selectedRating = r),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: (_selectedRating == null || _submittingRating) ? null : () => _submitRating(rest),
                child: _submittingRating
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Soumettre ma note'),
              ),
            ],

            if (_ratingSubmitted)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.star_rounded, size: 48, color: AppColors.secondary),
                      SizedBox(height: 8),
                      Text('Merci pour votre évaluation !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.rest});
  final RestitutionModel rest;

  Color get _color {
    switch (rest.status) {
      case 'completed': return AppColors.success;
      case 'scheduled': return AppColors.primary;
      default:          return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(rest.isCompleted ? Icons.check_circle_rounded : Icons.pending_rounded, color: _color),
          const SizedBox(width: 12),
          Text(rest.statusLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _color)),
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.onChanged});
  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i < rating;
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              active ? Icons.star_rounded : Icons.star_border_rounded,
              color: active ? AppColors.secondary : AppColors.onSurfaceVariant,
              size: 40,
            ),
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) =>
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.3));
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.value});
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.outline.withOpacity(0.4))),
    child: Row(
      children: [
        const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.onSurface, fontWeight: FontWeight.w500))),
      ],
    ),
  );
}
