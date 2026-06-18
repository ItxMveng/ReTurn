import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/declarations_notifier.dart';
import '../data/models/declaration_model.dart';

class DeclarationsListScreen extends ConsumerWidget {
  const DeclarationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(declarationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Déclarations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(declarationsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/declarations/create'),
        icon: const Icon(Icons.add),
        label: const Text('Déclarer'),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Erreur : ${state.error}',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(declarationsNotifierProvider.notifier)
                            .refresh(),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : state.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune déclaration pour l\'instant',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(declarationsNotifierProvider.notifier)
                          .refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.items.length +
                            (state.isFetchingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          if (i == state.items.length) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ));
                          }
                          return _DeclarationCard(
                              declaration: state.items[i]);
                        },
                      ),
                    ),
    );
  }
}

class _DeclarationCard extends StatelessWidget {
  final DeclarationModel declaration;
  const _DeclarationCard({required this.declaration});

  @override
  Widget build(BuildContext context) {
    final isFound = declaration.declarationType == 'found';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isFound ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            isFound ? Icons.find_in_page : Icons.search_off,
            color: isFound ? Colors.green : Colors.red,
          ),
        ),
        title: Text(declaration.ownerName ?? 'Inconnu'),
        subtitle: Text(
          '${declaration.documentType} • ${declaration.locationName ?? 'Lieu inconnu'}',
        ),
        trailing: Chip(
          label: Text(isFound ? 'Trouvé' : 'Perdu',
              style: const TextStyle(fontSize: 12)),
          backgroundColor: isFound ? Colors.green.shade50 : Colors.red.shade50,
        ),
        onTap: () => context.push('/declarations/${declaration.id}'),
      ),
    );
  }
}
