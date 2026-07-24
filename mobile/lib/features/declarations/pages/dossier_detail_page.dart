import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/declarations_provider.dart';
import '../widgets/declaration_card.dart';

/// Détail d'un dossier multi-documents : tous les documents d'un même
/// propriétaire (même group_id). Un tap sur un document ouvre son détail.
class DossierDetailPage extends ConsumerWidget {
  final String groupId;
  const DossierDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(declarationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.dossierTitle)),
      body: async.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppErrorView(
            error: e, onRetry: () => ref.invalidate(declarationsProvider)),
        data: (all) {
          final docs = all.where((d) => d.groupId == groupId).toList();
          if (docs.isEmpty) {
            return AppEmptyView(
                icon: Icons.folder_off_outlined, title: l.dossierEmpty);
          }
          final owner = docs.first.nomProprietaire;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // En-tête dossier : propriétaire + nombre de documents.
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.18),
                      cs.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: cs.primary.withValues(alpha: 0.2),
                    child: Icon(Icons.folder_shared_outlined, color: cs.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(owner,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(l.dossierDocsCount(docs.length),
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // Liste des documents du dossier.
              ...docs.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DeclarationCard(
                      declaration: d,
                      onTap: () => context.push('/declarations/${d.id}'),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}
