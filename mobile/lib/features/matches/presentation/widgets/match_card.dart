import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/match_model.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.onTap});
  final MatchModel match;
  final VoidCallback onTap;

  Color get _scoreColor {
    final s = match.scorePercent;
    if (s >= 80) return AppColors.success;
    if (s >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final found = match.declarationFound;
    final lost  = match.declarationLost;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outline.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Score badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _scoreColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${match.scorePercent}% de correspondance',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _scoreColor)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(match.statusLabel, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Types de documents
              Row(
                children: [
                  Expanded(
                    child: _DocChip(
                      label: found?.documentLabel ?? '?',
                      sublabel: found?.ownerName,
                      color: AppColors.success,
                      icon: Icons.search_rounded,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.sync_alt_rounded, color: AppColors.onSurfaceVariant.withOpacity(0.5), size: 18),
                  ),
                  Expanded(
                    child: _DocChip(
                      label: lost?.documentLabel ?? '?',
                      sublabel: lost?.ownerName,
                      color: AppColors.error,
                      icon: Icons.report_problem_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: match.score,
                  backgroundColor: _scoreColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  const _DocChip({required this.label, this.sublabel, required this.color, required this.icon});
  final String label;
  final String? sublabel;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (sublabel != null) Text(sublabel!, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
