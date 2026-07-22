import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/declaration.dart';

class DeclarationCard extends StatelessWidget {
  final Declaration declaration;
  final VoidCallback onTap;
  const DeclarationCard(
      {super.key, required this.declaration, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFound = declaration.type == DeclarationType.found;
    final color = isFound ? AppColors.kGreenDark : AppColors.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFound ? Icons.travel_explore : Icons.search_off,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${declaration.docTypeLabel} — '
                    '${declaration.typeLabel.toLowerCase()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(declaration.nomProprietaire,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6))),
                if (declaration.lieu != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 12,
                        color: cs.onSurface.withValues(alpha: 0.4)),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(declaration.lieu!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.45))),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusChip(status: declaration.status),
        ]),
      ),
    );
  }
}

/// Chip d'état de la déclaration (F-24) : Active / Matchée / Restituée.
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'matched' => ('Matchée', AppColors.secondary),
      'closed' => ('Restituée', AppColors.onSurfaceVariant),
      _ => ('Active', AppColors.kGreenDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
