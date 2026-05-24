import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/declaration.dart';
import '../providers/declarations_provider.dart';

class DeclarationDetailPage extends ConsumerWidget {
  final String id;
  const DeclarationDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(declarationDetailProvider(id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(e.toString())),
        data: (d) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chip(d.typeLabel,
                  d.type == DeclarationType.found
                      ? Colors.green
                      : Colors.orange),
              const SizedBox(height: 16),
              _row('Type de document', d.docTypeLabel),
              _row('Propriétaire', d.nomProprietaire),
              if (d.lieu != null) _row('Lieu', d.lieu!),
              if (d.description != null)
                _row('Description', d.description!),
              _row('Statut', d.status.name),
              _row('Date',
                  '${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}'),
              if (d.lat != null && d.lon != null)
                _row('Coordonnées',
                    '${d.lat!.toStringAsFixed(4)}, ${d.lon!.toStringAsFixed(4)}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
            const Divider(height: 24),
          ],
        ),
      );

  Widget _chip(String label, Color color) => Chip(
        label: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700)),
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide.none,
      );
}
