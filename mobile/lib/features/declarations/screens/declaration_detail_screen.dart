import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:return_mobile/core/theme/app_theme.dart';
import 'package:return_mobile/features/declarations/providers/declaration_provider.dart';
import 'package:return_mobile/shared/models/declaration.dart';
import 'package:return_mobile/shared/widgets/document_type_dropdown.dart';

class DeclarationDetailScreen extends ConsumerWidget {
  final String declarationId;
  const DeclarationDetailScreen({super.key, required this.declarationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final declarations = ref.watch(declarationListProvider).valueOrNull;
    final Declaration? decl =
        declarations?.where((d) => d.id == declarationId).firstOrNull;

    if (decl == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isFound = decl.isFound;
    final color = isFound ? kGreen : const Color(0xFFEF4444);
    final typeLabel = isFound ? 'Document trouvé' : 'Document perdu';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cs.brightness == Brightness.light
                      ? const [Color(0xFF0A1F16), Color(0xFF0D2B1F)]
                      : [cs.surface, cs.surfaceContainerHighest],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isFound ? Icons.search : Icons.report_outlined,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  typeLabel,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  documentTypeLabel(decl.documentType),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusChip(decl.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info card
                _InfoCard(
                  children: [
                    if (decl.documentNumber != null)
                      _InfoRow(
                          icon: Icons.numbers_outlined,
                          label: 'Numéro',
                          value: decl.documentNumber!),
                    if (decl.ownerName != null)
                      _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Titulaire',
                          value: decl.ownerName!),
                    if (decl.locationDescription != null)
                      _InfoRow(
                          icon: Icons.place_outlined,
                          label: 'Lieu',
                          value: decl.locationDescription!),
                    if (decl.latitude != null)
                      _InfoRow(
                          icon: Icons.my_location,
                          label: 'GPS',
                          value:
                              '${decl.latitude!.toStringAsFixed(5)}, ${decl.longitude!.toStringAsFixed(5)}'),
                    if (decl.description != null)
                      _InfoRow(
                          icon: Icons.notes_outlined,
                          label: 'Description',
                          value: decl.description!),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Date',
                      value: DateFormat('dd/MM/yyyy à HH:mm')
                          .format(decl.createdAt.toLocal()),
                    ),
                  ],
                ),

                // Photos
                if (decl.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Photos',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: decl.photoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          decl.photoUrls[i],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.broken_image_outlined,
                                color: cs.onSurface.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.brightness == Brightness.light
            ? Colors.white
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: children
            .expand((w) => [w, Divider(height: 1, color: cs.outline)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text('$label :',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5))),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 13, color: cs.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'matched' => const Color(0xFFF59E0B),
      'closed' => Colors.grey,
      _ => const Color(0xFF3B82F6),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
