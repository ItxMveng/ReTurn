import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/services/media_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../ocr/models/ocr_result.dart';
import '../../ocr/services/ocr_pipeline.dart';
import '../providers/declarations_provider.dart';
import '../repositories/declarations_repository.dart';

/// Types de documents supportés (alignés backend).
const _docTypes = <String>[
  'cni',
  'passport',
  'driving_license',
  'vehicle_registration',
  'birth_certificate',
  'student_card',
  'bank_card',
  'diploma',
  'other',
];

/// Normalise un nom pour le regroupement (casse + espaces).
String _normalizeName(String s) =>
    s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');

/// Un document scanné : son fichier + ses champs éditables (remplis par l'IA
/// puis corrigeables par l'utilisateur).
class _DocEntry {
  final String path;
  final TextEditingController ownerCtrl;
  final TextEditingController numberCtrl;
  String type;
  bool analyzing;
  _DocEntry(this.path)
      : ownerCtrl = TextEditingController(),
        numberCtrl = TextEditingController(),
        type = 'other',
        analyzing = true;

  void dispose() {
    ownerCtrl.dispose();
    numberCtrl.dispose();
  }
}

/// Déclaration de PLUSIEURS documents avec tri automatique par IA.
///
/// Principe : on ajoute/scanne plusieurs fichiers → chacun apparaît
/// **immédiatement** (la photo), l'OCR remplit les champs **en arrière-plan**
/// (nom, type, numéro), et l'utilisateur **vérifie/corrige** avant d'enregistrer.
/// Les documents sont **regroupés par propriétaire** (nom éditable) : un dossier
/// = une personne. Corriger un nom regroupe automatiquement les documents.
class MultiDocDeclarationPage extends ConsumerStatefulWidget {
  const MultiDocDeclarationPage({super.key});

  @override
  ConsumerState<MultiDocDeclarationPage> createState() =>
      _MultiDocDeclarationPageState();
}

class _MultiDocDeclarationPageState
    extends ConsumerState<MultiDocDeclarationPage> {
  late final OcrPipeline _ocr = OcrPipeline(ref.read(dioProvider));
  final _locationCtrl = TextEditingController();
  final List<_DocEntry> _docs = [];
  final List<_DocEntry> _ocrQueue = [];
  bool _draining = false;
  bool _found = true; // trouvé (par défaut) / perdu
  bool _submitting = false;

  @override
  void dispose() {
    _ocr.dispose();
    _locationCtrl.dispose();
    for (final d in _docs) {
      d.dispose();
    }
    super.dispose();
  }

  // ── Ajout de documents ────────────────────────────────────────────────────
  Future<void> _addFromGallery() async {
    final errorMsg = AppLocalizations.of(context).mdocError;
    try {
      final files =
          await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 1600);
      if (files.isEmpty) return;
      _addEntries(files.map((f) => f.path).toList());
    } catch (_) {
      _toast(errorMsg);
    }
  }

  Future<void> _addFromCamera() async {
    final picked = await MediaService.pickImage(
        source: ImageSource.camera, imageQuality: 85, maxWidth: 1600);
    if (picked.error != null) {
      _toast(picked.error!);
      return;
    }
    final file = picked.file;
    if (file == null) return;
    _addEntries([file.path]);
  }

  /// Ajoute immédiatement les documents (photos visibles tout de suite), puis
  /// lance l'OCR en arrière-plan pour remplir les champs.
  void _addEntries(List<String> paths) {
    setState(() {
      for (final p in paths) {
        final e = _DocEntry(p);
        _docs.add(e);
        _ocrQueue.add(e);
      }
    });
    _drainQueue();
  }

  /// Traite la file OCR un document à la fois (le TextRecognizer ML Kit n'aime
  /// pas les appels concurrents), avec un timeout pour ne jamais rester bloqué.
  Future<void> _drainQueue() async {
    if (_draining) return;
    _draining = true;
    while (_ocrQueue.isNotEmpty) {
      final e = _ocrQueue.removeAt(0);
      try {
        final OcrResult r = await _ocr
            .analyze(File(e.path))
            .timeout(const Duration(seconds: 25));
        final owner = [r.firstName, r.lastName]
            .where((s) => (s ?? '').trim().isNotEmpty)
            .map((s) => s!.trim())
            .join(' ');
        if (!mounted) return;
        setState(() {
          if (owner.isNotEmpty && e.ownerCtrl.text.trim().isEmpty) {
            e.ownerCtrl.text = owner;
          }
          if (r.kind.backendType != 'other') e.type = r.kind.backendType;
          final num = r.documentNumber?.trim() ?? '';
          if (num.isNotEmpty && e.numberCtrl.text.trim().isEmpty) {
            e.numberCtrl.text = num;
          }
          e.analyzing = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => e.analyzing = false);
      }
    }
    _draining = false;
  }

  void _removeDoc(_DocEntry e) {
    setState(() {
      _ocrQueue.remove(e);
      _docs.remove(e);
      e.dispose();
    });
  }

  /// Nombre de personnes distinctes détectées (par nom normalisé).
  int get _peopleCount =>
      _docs.map((d) => _normalizeName(d.ownerCtrl.text)).where((k) => k.isNotEmpty).toSet().length;

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_docs.isEmpty) return;
    if (_docs.any((d) => d.ownerCtrl.text.trim().isEmpty)) {
      _toast(l.mdocOwnerRequired);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);

    // Regroupement par propriétaire (nom normalisé) → un dossier par personne.
    final groups = <String, List<_DocEntry>>{};
    for (final d in _docs) {
      groups.putIfAbsent(_normalizeName(d.ownerCtrl.text), () => []).add(d);
    }

    final repo = ref.read(declarationsRepositoryProvider);
    final location = _locationCtrl.text.trim();
    try {
      for (final entry in groups.values) {
        final owner = entry.first.ownerCtrl.text.trim();
        final items = entry
            .map((d) => <String, dynamic>{
                  'document_type': d.type,
                  'document_number': d.numberCtrl.text.trim().isEmpty
                      ? null
                      : d.numberCtrl.text.trim(),
                  'owner_name': owner,
                })
            .toList();
        await repo.createDossierWithPhotos(
          {
            'declaration_type': _found ? 'found' : 'lost',
            if (location.isNotEmpty) 'location_description': location,
          },
          items,
          entry.map((d) => d.path).toList(),
        );
      }
      ref.invalidate(declarationsProvider);
      if (!mounted) return;
      final count = groups.length;
      context.pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.mdocSuccess(count))));
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _toast(l.mdocError);
      }
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasDocs = _docs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l.mdocTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Type trouvé / perdu.
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: true, label: Text(l.declTagFound)),
                      ButtonSegment(value: false, label: Text(l.declTagLost)),
                    ],
                    selected: {_found},
                    onSelectionChanged: (s) => setState(() => _found = s.first),
                  ),
                  const SizedBox(height: 16),

                  if (!hasDocs) ...[
                    _IntroCard(text: l.mdocIntro),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(l.mdocEmpty,
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5))),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    if (_peopleCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(l.mdocDetected(_peopleCount),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cs.primary)),
                      ),
                    ..._docs.map((d) => _DocCard(
                          entry: d,
                          onRemove: () => _removeDoc(d),
                          onChanged: () => setState(() {}),
                        )),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _locationCtrl,
                      decoration: InputDecoration(
                        labelText: l.mdocLocation,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Boutons d'ajout — toujours actifs (chaque ajout est indépendant).
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l.mdocAddGallery),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _addFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(l.mdocTakePhotos),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            if (hasDocs)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l.mdocSubmit(
                          _peopleCount == 0 ? 1 : _peopleCount)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final String text;
  const _IntroCard({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.auto_awesome_outlined, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: cs.onSurface.withValues(alpha: 0.75))),
        ),
      ]),
    );
  }
}

/// Carte d'un document scanné : photo + champs éditables (nom, type, numéro).
class _DocCard extends StatelessWidget {
  final _DocEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  const _DocCard({
    required this.entry,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Vignette + indicateur d'analyse.
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(entry.path),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 58,
                  height: 58,
                  color: cs.primary.withValues(alpha: 0.08),
                  child: Icon(Icons.image_outlined,
                      color: cs.onSurface.withValues(alpha: 0.3)),
                ),
              ),
            ),
            if (entry.analyzing)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: entry.ownerCtrl,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                isDense: true,
                labelText: l.mdocDossierOwner,
                hintText:
                    entry.analyzing ? l.mdocAnalyzing : l.mdocOwnerHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            tooltip: l.mdocRemove,
            onPressed: onRemove,
            icon: Icon(Icons.close,
                size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              // La clé change quand l'OCR met à jour le type → le menu reflète
              // bien le type détecté après l'analyse.
              key: ValueKey('${entry.path}#${entry.type}'),
              initialValue: entry.type,
              isDense: true,
              decoration: const InputDecoration(
                  isDense: true, border: OutlineInputBorder()),
              items: _docTypes
                  .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(l.docType(t),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  entry.type = v;
                  onChanged();
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextField(
              controller: entry.numberCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                isDense: true,
                labelText: l.declDocNumber,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
