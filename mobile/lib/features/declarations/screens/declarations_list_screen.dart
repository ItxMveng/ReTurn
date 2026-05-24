import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:docretour/core/theme/app_theme.dart';
import 'package:docretour/features/declarations/providers/declaration_provider.dart';
import 'package:docretour/l10n/app_localizations.dart';
import 'package:docretour/shared/models/declaration.dart';
import 'package:docretour/shared/widgets/document_type_dropdown.dart';

// ─── Providers locaux search/filter ──────────────────────────────────────────
final _searchQueryProvider = StateProvider<String>((ref) => '');
final _filterStatusProvider = StateProvider<String?>((ref) => null); // null = tous
final _sortModeProvider = StateProvider<_SortMode>((ref) => _SortMode.dateDesc);

enum _SortMode { dateDesc, dateAsc, statusMatched, statusActive }

extension _SortModeLabel on _SortMode {
  String label() {
    switch (this) {
      case _SortMode.dateDesc:      return 'Plus récent';
      case _SortMode.dateAsc:       return 'Plus ancien';
      case _SortMode.statusMatched: return 'Matchés en 1er';
      case _SortMode.statusActive:  return 'Actifs en 1er';
    }
  }
}

final _filteredDeclarationsProvider = Provider<List<Declaration>>((ref) {
  final allAsync = ref.watch(declarationListProvider);
  final all = allAsync.valueOrNull ?? [];
  final query = ref.watch(_searchQueryProvider).toLowerCase().trim();
  final status = ref.watch(_filterStatusProvider);
  final sort = ref.watch(_sortModeProvider);

  var filtered = all.where((d) {
    final matchStatus = status == null || d.status == status;
    final matchQuery = query.isEmpty ||
        (d.documentType.toLowerCase().contains(query)) ||
        (d.documentNumber?.toLowerCase().contains(query) ?? false) ||
        (d.ownerName?.toLowerCase().contains(query) ?? false) ||
        (d.locationDescription?.toLowerCase().contains(query) ?? false);
    return matchStatus && matchQuery;
  }).toList();

  filtered.sort((a, b) {
    switch (sort) {
      case _SortMode.dateDesc:
        return b.createdAt.compareTo(a.createdAt);
      case _SortMode.dateAsc:
        return a.createdAt.compareTo(b.createdAt);
      case _SortMode.statusMatched:
        final score = (Declaration d) =>
            d.status == 'matched' ? 0 : d.status == 'active' ? 1 : 2;
        return score(a).compareTo(score(b));
      case _SortMode.statusActive:
        final score = (Declaration d) =>
            d.status == 'active' ? 0 : d.status == 'matched' ? 1 : 2;
        return score(a).compareTo(score(b));
    }
  });

  return filtered;
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class DeclarationsListScreen extends ConsumerStatefulWidget {
  const DeclarationsListScreen({super.key});

  @override
  ConsumerState<DeclarationsListScreen> createState() =>
      _DeclarationsListScreenState();
}

class _DeclarationsListScreenState
    extends ConsumerState<DeclarationsListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final declarations = ref.watch(_filteredDeclarationsProvider);
    final isLoading =
        ref.watch(declarationListProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.declarationsTitle),
        backgroundColor: cs.secondary,
        foregroundColor: Colors.white,
        actions: [
          // Sort menu
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Trier',
            onSelected: (mode) =>
                ref.read(_sortModeProvider.notifier).state = mode,
            itemBuilder: (_) => _SortMode.values
                .map((m) => PopupMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          if (ref.read(_sortModeProvider) == m)
                            const Icon(Icons.check,
                                size: 16, color: kGreen)
                          else
                            const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Text(m.label()),
                        ],
                      ),
                    ))
                .toList(),
          ),
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
            tooltip: "J'ai trouvé un document",
            child: const Icon(Icons.search, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'lost',
            onPressed: () => context.push('/declarations/new/lost'),
            backgroundColor: const Color(0xFFEF4444),
            tooltip: "J'ai perdu un document",
            child: const Icon(Icons.report_outlined, color: Colors.white),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          // ── Search + Filter bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      ref.read(_searchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par type, n°, propriétaire…',
                    prefixIcon:
                        const Icon(Icons.search, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref
                                  .read(_searchQueryProvider.notifier)
                                  .state = '';
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outline)),
                    filled: true,
                    fillColor: cs.surface,
                  ),
                ),
                const SizedBox(height: 8),
                // Filtres statut
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                          label: 'Tous',
                          value: null,
                          cs: cs),
                      const SizedBox(width: 6),
                      _FilterChip(
                          label: '🔵 Actif',
                          value: 'active',
                          cs: cs),
                      const SizedBox(width: 6),
                      _FilterChip(
                          label: '✅ Matché',
                          value: 'matched',
                          cs: cs),
                      const SizedBox(width: 6),
                      _FilterChip(
                          label: '🔒 Traité',
                          value: 'closed',
                          cs: cs),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Liste ────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : declarations.isEmpty
                    ? _EmptyState(l: l)
                    : RefreshIndicator(
                        color: kGreen,
                        onRefresh: () =>
                            ref
                                .read(declarationListProvider.notifier)
                                .refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              12, 8, 12, 120),
                          itemCount: declarations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _DeclarationCard(
                            declaration: declarations[i],
                            onTap: () => context.push(
                                '/declarations/${declarations[i].id}'),
                            onDelete: () async {
                              final confirmed =
                                  await _confirmDelete(context, l);
                              if (confirmed == true) {
                                await ref
                                    .read(declarationListProvider
                                        .notifier)
                                    .delete(declarations[i].id);
                              }
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, AppLocalizations l) =>
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
                    style: const TextStyle(
                        color: Color(0xFFEF4444)))),
          ],
        ),
      );
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends ConsumerWidget {
  final String label;
  final String? value;
  final ColorScheme cs;
  const _FilterChip(
      {required this.label, required this.value, required this.cs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(_filterStatusProvider) == value;
    return GestureDetector(
      onTap: () =>
          ref.read(_filterStatusProvider.notifier).state = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kGreen : cs.surface,
          border: Border.all(
              color: selected ? kGreen : cs.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Declaration card ──────────────────────────────────────────────────────────

class _DeclarationCard extends StatelessWidget {
  final Declaration declaration;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeclarationCard(
      {required this.declaration,
      required this.onTap,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFound = declaration.isFound;
    final color =
        isFound ? kGreen : const Color(0xFFEF4444);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: cs.brightness == Brightness.light
              ? Colors.white
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: declaration.status == 'matched'
                  ? kGreen.withValues(alpha: 0.5)
                  : cs.outline),
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
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFound
                  ? Icons.search
                  : Icons.report_outlined,
              color: color,
              size: 22,
            ),
          ),
          title: Text(
            documentTypeLabel(declaration.documentType),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cs.onSurface),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (declaration.documentNumber != null)
                Text('N° ${declaration.documentNumber}',
                    style: TextStyle(
                        color:
                            cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13)),
              if (declaration.ownerName != null)
                Text(declaration.ownerName!,
                    style: TextStyle(
                        color:
                            cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 13)),
              Text(
                DateFormat('dd/MM/yyyy HH:mm')
                    .format(declaration.createdAt.toLocal()),
                style: TextStyle(
                    color:
                        cs.onSurface.withValues(alpha: 0.4),
                    fontSize: 12),
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

// ── Status chip ───────────────────────────────────────────────────────────────

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
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

// ── Empty state ───────────────────────────────────────────────────────────────

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
                    color:
                        cs.onSurface.withValues(alpha: 0.5),
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}
