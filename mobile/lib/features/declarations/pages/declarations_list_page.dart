import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/declaration.dart';
import '../providers/declarations_provider.dart';
import '../widgets/declaration_card.dart';

class DeclarationsListPage extends ConsumerWidget {
  const DeclarationsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(declarationsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Déclarations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nouvelle déclaration',
            onPressed: () => context.go('/declarations/new'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline, color: cs.error, size: 48),
            const SizedBox(height: 12),
            Text(e.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => ref.invalidate(declarationsProvider),
                child: const Text('Réessayer')),
          ]),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: cs.onSurface.withOpacity(0.25)),
                  const SizedBox(height: 16),
                  const Text('Aucune déclaration',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Créez votre première déclaration',
                      style: TextStyle(
                          color: cs.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/declarations/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle déclaration'),
                  ),
                ]),
              )
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(declarationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => DeclarationCard(
                    declaration: items[i],
                    onTap: () =>
                        context.go('/declarations/${items[i].id}'),
                  ),
                ),
              ),
      ),
      floatingActionButton: async.valueOrNull?.isNotEmpty == true
          ? FloatingActionButton(
              onPressed: () => context.go('/declarations/new'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
