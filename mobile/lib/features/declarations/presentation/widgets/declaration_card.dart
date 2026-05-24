import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/declaration_model.dart';

class DeclarationCard extends StatelessWidget {
  const DeclarationCard({
    super.key,
    required this.declaration,
    required this.onTap,
    this.onDelete,
  });
  final DeclarationModel declaration;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final decl = declaration;
    final isFound = decl.isFound;
    final typeColor = isFound ? AppColors.success : AppColors.error;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─ Icône type ─
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFound ? Icons.search_rounded : Icons.report_problem_rounded,
                  color: typeColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // ─ Contenu ─
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            decl.documentLabel,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            decl.typeLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor),
                          ),
                        ),
                      ],
                    ),
                    if (decl.ownerName != null) ...
                      [const SizedBox(height: 4), Text(decl.ownerName!, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant))],
                    if (decl.locationDescription != null) ...
                      [const SizedBox(height: 4), Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(child: Text(decl.locationDescription!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant))),
                        ],
                      )],
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(decl.createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // ─ Menu supérieur droit ─
              if (onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (v) { if (v == 'delete') onDelete!(); },
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.onSurfaceVariant),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'delete', child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: AppColors.error)),
                      ],
                    )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      final diff = DateTime.now().difference(d);
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} mois';
      if (diff.inDays > 0) return 'Il y a ${diff.inDays} j';
      if (diff.inHours > 0) return 'Il y a ${diff.inHours} h';
      if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes} min';
      return 'Maintenant';
    } catch (_) {
      return '';
    }
  }
}
