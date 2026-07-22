import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/media_url.dart';
import '../models/declaration.dart';
import '../providers/declarations_provider.dart';
import '../repositories/declarations_repository.dart';

class DeclarationDetailPage extends ConsumerWidget {
  final String id;
  const DeclarationDetailPage({super.key, required this.id});

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context,
        title: 'Annuler la déclaration',
        message:
            'Elle ne sera plus active pour le matching, mais restera dans votre '
            'historique. Continuer ?',
        confirmLabel: 'Annuler la déclaration');
    if (ok != true) return;
    try {
      await ref.read(declarationsRepositoryProvider).cancel(id);
      ref.invalidate(declarationsProvider);
      ref.invalidate(declarationDetailProvider(id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déclaration annulée.')),
        );
      }
    } catch (_) {
      if (context.mounted) _toastError(context);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context,
        title: 'Supprimer la déclaration',
        message:
            'Cette action est définitive. La déclaration et ses photos seront '
            'supprimées. Continuer ?',
        confirmLabel: 'Supprimer',
        danger: true);
    if (ok != true) return;
    try {
      await ref.read(declarationsRepositoryProvider).delete(id);
      ref.invalidate(declarationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déclaration supprimée.')),
        );
        context.pop();
      }
    } catch (_) {
      if (context.mounted) _toastError(context);
    }
  }

  void _toastError(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Action impossible, réessayez.'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Retour')),
          FilledButton(
            style: danger
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error)
                : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Aperçu plein écran (zoom) + bouton pour ouvrir/télécharger l'image.
  void _viewImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Télécharger / Ouvrir',
              icon: const Icon(Icons.download_rounded),
              onPressed: () async {
                final uri = Uri.parse(mediaUrl(url));
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 5,
            child: Image.network(mediaUrl(url), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(declarationDetailProvider(id));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail de la déclaration')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (d) {
          final isFound = d.type == DeclarationType.found;
          final accent = isFound ? cs.primary : Colors.orange;
          final closed = d.status == 'closed';
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── En-tête ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: accent.withValues(alpha: 0.2),
                      child: Icon(
                          isFound ? Icons.travel_explore : Icons.search_off,
                          color: accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.docTypeLabel,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Row(children: [
                            _Pill(text: d.typeLabel, color: accent),
                            const SizedBox(width: 6),
                            _Pill(
                              text: closed
                                  ? 'Terminée'
                                  : d.status == 'matched'
                                      ? 'Matchée'
                                      : 'Active',
                              color: closed
                                  ? Colors.grey
                                  : d.status == 'matched'
                                      ? Colors.orange
                                      : cs.primary,
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Photos ────────────────────────────────────────────────
              if (d.allPhotoUrls.isNotEmpty) ...[
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: d.allPhotoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _viewImage(context, d.allPhotoUrls[i]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Image.network(mediaUrl(d.allPhotoUrls[i]),
                                width: 220, height: 160, fit: BoxFit.cover),
                            const Positioned(
                              right: 8,
                              bottom: 8,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.zoom_in,
                                    size: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Correspondance trouvée (F-20) ────────────────────────
              if (d.status == 'matched') ...[
                Material(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => context.go('/matches'),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Icon(Icons.compare_arrows, color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Correspondance trouvée',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: cs.primary)),
                              const SizedBox(height: 2),
                              Text('Consultez vos matchs pour confirmer.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: cs.primary),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Informations ──────────────────────────────────────────
              _InfoCard(rows: [
                _InfoRow(
                    Icons.person_outline, 'Propriétaire', d.nomProprietaire),
                if (d.lieu != null)
                  _InfoRow(Icons.location_on_outlined,
                      isFound ? 'Lieu de découverte' : 'Lieu de perte', d.lieu!),
                if (d.description != null && d.description!.isNotEmpty)
                  _InfoRow(Icons.notes, 'Description', d.description!),
                if (d.createdAtDate != null)
                  _InfoRow(
                      Icons.event_outlined,
                      'Déclaré le',
                      '${d.createdAtDate!.day}/${d.createdAtDate!.month}/${d.createdAtDate!.year}'),
              ]),
              const SizedBox(height: 28),

              // ── Actions (sur ses propres déclarations) ────────────────
              if (!closed)
                OutlinedButton.icon(
                  onPressed: () => _cancel(context, ref),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler la déclaration'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _delete(context, ref),
                icon: Icon(Icons.delete_outline, color: cs.error),
                label: Text('Supprimer la déclaration',
                    style: TextStyle(color: cs.error)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoCard({required this.rows});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(height: 1, color: cs.outlineVariant, indent: 52),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
