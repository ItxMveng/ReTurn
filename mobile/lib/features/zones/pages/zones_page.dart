import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/appear.dart';
import '../repositories/zone_repository.dart';

/// Répertoire des zones de récupération certifiées (F-32).
class ZonesPage extends ConsumerWidget {
  const ZonesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zones de récupération')),
      body: const _ZonesBody(onTap: null),
    );
  }
}

/// Bottom-sheet de sélection d'une zone certifiée (pour un rendez-vous).
Future<Zone?> pickCertifiedZone(BuildContext context) {
  return showModalBottomSheet<Zone>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choisir une zone certifiée',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
          Expanded(
            child: _ZonesBody(
              scrollController: scroll,
              onTap: (z) => Navigator.pop(ctx, z),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ZonesBody extends ConsumerWidget {
  final ValueChanged<Zone>? onTap;
  final ScrollController? scrollController;
  const _ZonesBody({required this.onTap, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(zonesProvider);
    final cs = Theme.of(context).colorScheme;
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (zones) => zones.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_off_outlined,
                    size: 52, color: cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(height: 12),
                const Text('Aucune zone certifiée pour le moment',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
            )
          : ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: zones.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => Appear(
                delay: Duration(milliseconds: (i * 40).clamp(0, 320)),
                child: _ZoneTile(zone: zones[i], onTap: onTap),
              ),
            ),
    );
  }
}

class _ZoneTile extends StatelessWidget {
  final Zone zone;
  final ValueChanged<Zone>? onTap;
  const _ZoneTile({required this.zone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(zone),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: zone.isCertified
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              zone.isCertified
                  ? Icons.local_police_outlined
                  : Icons.place_outlined,
              color: zone.isCertified
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(zone.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text('${zone.typeLabel} · ${zone.address}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: zone.isCertified
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(zone.isCertified ? 'Certifiée' : 'Partenaire',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: zone.isCertified
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.55))),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.4)),
        ]),
      ),
    );
  }
}
