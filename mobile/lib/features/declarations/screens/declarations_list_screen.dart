import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/declarations_provider.dart';
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
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (declarations) => declarations.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Aucune déclaration pour l'instant',
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
                  itemCount: declarations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) =>
                      _DeclarationCard(declaration: declarations[i]),
                ),
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
        title: Text(declaration.ownerName),
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
