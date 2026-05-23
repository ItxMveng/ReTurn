import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/declarations/providers/declaration_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/models/declaration.dart';
import 'package:docretour/shared/widgets/document_type_dropdown.dart';

class DeclarationsListScreen extends ConsumerWidget {
  const DeclarationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final asyncDeclarations = ref.watch(declarationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.declarationsTitle),
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () =>
                ref.read(declarationListProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'found',
            onPressed: () => context.push('/declarations/new/found'),
            backgroundColor: kGreen,
            tooltip: 'J\'ai trouvé un document',
            child: const Icon(Icons.search, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'lost',
            onPressed: () => context.push('/declarations/new/lost'),
            backgroundColor: const Color(0xFFEF4444),
            tooltip: 'J\'ai perdu un document',
            child: const Icon(Icons.report_outlined, color: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: asyncDeclarations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (declarations) {
          if (declarations.isEmpty) {
            return _EmptyState(l: l);
          }
          return RefreshIndicator(
            color: kGreen,
            onRefresh: () =>
                ref.read(declarationListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: declarations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _DeclarationCard(
                declaration: declarations[i],
                onTap: () => context.push('/declarations/${declarations[i].id}'),
                onDelete: () async {
                  final confirmed = await _confirmDelete(context, l);
                  if (confirmed == true) {
                    await ref
                        .read(declarationListProvider.notifier)
                        .delete(declarations[i].id);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, AppLocalizations l) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(l.confirmDelete),
          content: Text(l.confirmDeleteDesc),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.delete,
                    style: const TextStyle(color: Color(0xFFEF4444)))),
          ],
        ),
      );
}

class _DeclarationCard extends StatelessWidget {
  final Declaration declaration;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeclarationCard(
      {required this.declaration, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFound = declaration.isFound;
    final color = isFound ? kGreen : const Color(0xFFEF4444);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.brightness == Brightness.light
              ? Colors.white
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
          boxShadow: cs.brightness == Brightness.light
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFound ? Icons.search : Icons.report_outlined,
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            documentTypeLabel(declaration.documentType),
            style:
                TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (declaration.documentNumber != null)
                Text('N\u00b0 ${declaration.documentNumber}',
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13)),
              if (declaration.ownerName != null)
                Text(declaration.ownerName!,
                    style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13)),
              Text(
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(declaration.createdAt.toLocal()),
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusChip(declaration.status),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFFEF4444)),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'matched' => ('✅ Matché', const Color(0xFF22C55E)),
      'closed'  => ('🔒 Traité', Colors.grey),
      _         => ('🔵 Actif', const Color(0xFF3B82F6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l;
  const _EmptyState({required this.l});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: kGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined,
                  size: 48, color: kGreen),
            ),
            const SizedBox(height: 20),
            Text(l.declarationsEmpty,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 10),
            Text(l.declarationsEmptyDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5), height: 1.5)),
          ],
        ),
      ),
    );
  }
}
