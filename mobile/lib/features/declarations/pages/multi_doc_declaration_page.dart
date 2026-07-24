import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/media_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../ocr/models/ocr_result.dart';
import '../../ocr/services/ocr_service.dart';
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

/// Un document (un fichier) dans un dossier.
class _DocRow {
  final String path;
  String type;
  final TextEditingController numberCtrl;
  _DocRow(this.path, {required this.type, String number = ''})
      : numberCtrl = TextEditingController(text: number);
}

/// Un dossier = une personne identifiée + ses documents.
class _Dossier {
  final TextEditingController ownerCtrl;
  final List<_DocRow> docs;
  _Dossier({String owner = '', required this.docs})
      : ownerCtrl = TextEditingController(text: owner);
}

/// Déclaration « plusieurs documents » avec tri automatique par IA (OCR) :
/// on ajoute/photographie plusieurs fichiers, l'app lit chacun, regroupe les
/// documents par propriétaire détecté (un dossier par personne), puis on
/// confirme/corrige avant d'enregistrer.
class MultiDocDeclarationPage extends ConsumerStatefulWidget {
  const MultiDocDeclarationPage({super.key});

  @override
  ConsumerState<MultiDocDeclarationPage> createState() =>
      _MultiDocDeclarationPageState();
}

class _MultiDocDeclarationPageState
    extends ConsumerState<MultiDocDeclarationPage> {
  final _ocr = OcrService();
  final _locationCtrl = TextEditingController();
  final List<_Dossier> _dossiers = [];
  bool _analyzing = false;
  bool _submitting = false;

  @override
  void dispose() {
    _ocr.dispose();
    _locationCtrl.dispose();
    for (final d in _dossiers) {
      d.ownerCtrl.dispose();
      for (final doc in d.docs) {
        doc.numberCtrl.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _addFromGallery() async {
    final errorMsg = AppLocalizations.of(context).mdocError;
    try {
      final files = await ImagePicker()
          .pickMultiImage(imageQuality: 85, maxWidth: 1600);
      if (files.isEmpty) return;
      await _analyze(files.map((f) => f.path).toList());
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
    await _analyze([file.path]);
  }

  /// OCR chaque fichier puis fusionne dans les dossiers existants par nom.
  Future<void> _analyze(List<String> paths) async {
    setState(() => _analyzing = true);
    for (final path in paths) {
      String owner = '';
      String type = 'other';
      String number = '';
      try {
        final OcrResult r = await _ocr.processImage(File(path));
        owner = [r.firstName, r.lastName]
            .where((s) => (s ?? '').trim().isNotEmpty)
            .map((s) => s!.trim())
            .join(' ');
        type = r.kind.backendType;
        number = r.documentNumber?.trim() ?? '';
      } catch (_) {
        // OCR raté : document ajouté sans nom, l'utilisateur complètera.
      }
      _mergeIntoDossier(path, owner: owner, type: type, number: number);
    }
    if (mounted) setState(() => _analyzing = false);
  }

  void _mergeIntoDossier(String path,
      {required String owner, required String type, required String number}) {
    final key = _normalizeName(owner);
    final doc = _DocRow(path, type: type, number: number);
    if (key.isNotEmpty) {
      for (final d in _dossiers) {
        if (_normalizeName(d.ownerCtrl.text) == key) {
          d.docs.add(doc);
          return;
        }
      }
    }
    _dossiers.add(_Dossier(owner: owner, docs: [doc]));
  }

  void _removeDoc(_Dossier d, _DocRow doc) {
    setState(() {
      doc.numberCtrl.dispose();
      d.docs.remove(doc);
      if (d.docs.isEmpty) {
        d.ownerCtrl.dispose();
        _dossiers.remove(d);
      }
    });
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    if (_dossiers.any((d) => d.ownerCtrl.text.trim().isEmpty)) {
      _toast(l.mdocOwnerRequired);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    final repo = ref.read(declarationsRepositoryProvider);
    final location = _locationCtrl.text.trim();
    try {
      for (final d in _dossiers) {
        final owner = d.ownerCtrl.text.trim();
        final items = d.docs
            .map((doc) => <String, dynamic>{
                  'document_type': doc.type,
                  'document_number': doc.numberCtrl.text.trim().isEmpty
                      ? null
                      : doc.numberCtrl.text.trim(),
                  'owner_name': owner,
                })
            .toList();
        await repo.createDossierWithPhotos(
          {
            // Ce parcours concerne les documents TROUVÉS (on a les fichiers en
            // main → scan/OCR/tri). La perte se déclare via le formulaire
            // descriptif dédié.
            'declaration_type': 'found',
            if (location.isNotEmpty) 'location_description': location,
          },
          items,
          d.docs.map((doc) => doc.path).toList(),
        );
      }
      ref.invalidate(declarationsProvider);
      if (!mounted) return;
      final count = _dossiers.length;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.mdocSuccess(count))),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        _toast(l.mdocError);
      }
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasDocs = _dossiers.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l.mdocTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (!hasDocs && !_analyzing) ...[
                    _IntroCard(text: l.mdocIntro),
                    const SizedBox(height: 20),
                  ],

                  if (_analyzing) ...[
                    Row(children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(l.mdocAnalyzing),
                    ]),
                    const SizedBox(height: 16),
                  ],

                  if (hasDocs) ...[
                    Text(l.mdocDetected(_dossiers.length),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.primary)),
                    const SizedBox(height: 12),
                    ..._dossiers.map((d) => _DossierCard(
                          dossier: d,
                          onRemoveDoc: (doc) => _removeDoc(d, doc),
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
                  ] else if (!_analyzing)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(l.mdocEmpty,
                            style: TextStyle(
                                color:
                                    cs.onSurface.withValues(alpha: 0.5))),
                      ),
                    ),

                  // Boutons d'ajout.
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _analyzing ? null : _addFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(l.mdocAddGallery),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _analyzing ? null : _addFromCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(l.mdocTakePhotos),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            // CTA final.
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
                      : Text(l.mdocSubmit(_dossiers.length)),
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

class _DossierCard extends StatelessWidget {
  final _Dossier dossier;
  final void Function(_DocRow) onRemoveDoc;
  final VoidCallback onChanged;
  const _DossierCard({
    required this.dossier,
    required this.onRemoveDoc,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.folder_shared_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: dossier.ownerCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: l.mdocDossierOwner,
                  hintText: l.mdocOwnerHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...dossier.docs.map((doc) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(doc.path),
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 46,
                        height: 46,
                        color: cs.primary.withValues(alpha: 0.08),
                        child: Icon(Icons.image_outlined,
                            size: 20,
                            color: cs.onSurface.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(children: [
                      DropdownButtonFormField<String>(
                        initialValue: doc.type,
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
                            doc.type = v;
                            onChanged();
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: doc.numberCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l.declDocNumber,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ]),
                  ),
                  IconButton(
                    tooltip: l.mdocRemove,
                    onPressed: () => onRemoveDoc(doc),
                    icon: Icon(Icons.close,
                        size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ]),
              )),
        ],
      ),
    );
  }
}
