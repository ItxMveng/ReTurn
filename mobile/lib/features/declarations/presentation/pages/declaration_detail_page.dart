import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/declarations_notifier.dart';
import '../../data/models/declaration_model.dart';

class DeclarationDetailPage extends ConsumerWidget {
  const DeclarationDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDecl = ref.watch(declarationDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail de la déclaration'),
        leading: BackButton(onPressed: () => context.goNamed(RouteNames.declarations)),
      ),
      body: asyncDecl.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        data: (decl) => _DeclarationBody(decl: decl),
      ),
    );
  }
}

class _DeclarationBody extends StatelessWidget {
  const _DeclarationBody({required this.decl});
  final DeclarationModel decl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─ Badges type ─
        Row(
          children: [
            _Badge(
              label: decl.typeLabel,
              color: decl.isFound ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 8),
            _Badge(label: decl.documentLabel, color: AppColors.primary),
            const Spacer(),
            _Badge(
              label: decl.status.toUpperCase(),
              color: decl.status == 'active'
                  ? AppColors.success
                  : AppColors.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─ Photos ─
        if (decl.allPhotoUrls.isNotEmpty) ..._buildPhotos(decl.allPhotoUrls),

        // ─ Informations document ─
        _InfoSection(
          title: 'Informations sur le document',
          items: [
            if (decl.ownerName != null)
              _InfoRow(label: 'Propriétaire', value: decl.ownerName!),
            if (decl.documentNumber != null)
              _InfoRow(label: 'Numéro', value: decl.documentNumber!),
          ],
        ),

        // ─ Lieu & date ─
        if (decl.locationDescription != null || decl.eventDate != null)
          _InfoSection(
            title: 'Lieu & date',
            items: [
              if (decl.locationDescription != null)
                _InfoRow(
                  label: 'Lieu',
                  value: decl.locationDescription!,
                ),
              if (decl.eventDate != null)
                _InfoRow(
                  label: 'Date',
                  value: _formatDate(decl.eventDate!),
                ),
            ],
          ),

        // ─ Description ─
        if (decl.description != null)
          _InfoSection(
            title: 'Description',
            items: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  decl.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurface,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),

        // ─ Infos techniques ─
        _InfoSection(
          title: 'Informations techniques',
          items: [
            _InfoRow(label: 'ID', value: decl.id),
            _InfoRow(
              label: 'Créée le',
              value: decl.createdAt != null ? _formatDateStr(decl.createdAt!) : '—',
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  List<Widget> _buildPhotos(List<String> urls) {
    return [
      SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              urls[i],
              width: 240,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 240,
                color: AppColors.surfaceVariant,
                child: const Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  // Formate un DateTime directement
  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}'
        '/${d.month.toString().padLeft(2, '0')}'
        '/${d.year} à '
        '${d.hour.toString().padLeft(2, '0')}h'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  // Formate une String ISO
  String _formatDateStr(String iso) {
    try {
      return _formatDate(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        // Remplacement de withOpacity (déprécié) par withValues
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            // Remplacement de withOpacity (déprécié) par withValues
            border: Border.all(
              color: AppColors.outline.withValues(alpha: 0.5),
            ),
          ),
          child: Column(children: items),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
