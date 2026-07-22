import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/media_service.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/declarations_provider.dart';
import '../repositories/declarations_repository.dart';

/// Types de documents supportés (alignés sur le backend — F-16).
const _docTypes = <String, String>{
  'cni': "Carte Nationale d'Identité",
  'passport': 'Passeport',
  'driving_license': 'Permis de conduire',
  'student_card': 'Carte étudiante',
  'bank_card': 'Carte bancaire',
  'vehicle_registration': 'Carte grise',
  'birth_certificate': 'Acte de naissance',
  'diploma': 'Diplôme',
  'other': 'Autre',
};

/// Libellés courts pour la grille d'icônes (Fast Path).
const _shortDocLabels = <String, String>{
  'cni': 'CNI',
  'passport': 'Passeport',
  'driving_license': 'Permis',
  'student_card': 'Carte étudiante',
  'bank_card': 'Carte bancaire',
  'vehicle_registration': 'Carte grise',
  'birth_certificate': 'Acte naissance',
  'diploma': 'Diplôme',
  'other': 'Autre',
};

const _docIcons = <String, IconData>{
  'cni': Icons.badge_outlined,
  'passport': Icons.menu_book_outlined,
  'driving_license': Icons.directions_car_outlined,
  'student_card': Icons.school_outlined,
  'bank_card': Icons.credit_card_outlined,
  'vehicle_registration': Icons.article_outlined,
  'birth_certificate': Icons.child_care_outlined,
  'diploma': Icons.workspace_premium_outlined,
  'other': Icons.description_outlined,
};

/// Formulaire de déclaration « Fast Path » (3 taps) : type + nom + Déclarer.
/// Tout le reste est optionnel dans la section « Enrichir ma déclaration ».
class DeclarationFormPage extends ConsumerStatefulWidget {
  final String declarationType; // 'found' ou 'lost'
  const DeclarationFormPage({super.key, required this.declarationType});

  @override
  ConsumerState<DeclarationFormPage> createState() =>
      _DeclarationFormPageState();
}

class _DeclarationFormPageState extends ConsumerState<DeclarationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameCtrl = TextEditingController();
  final _docNumCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _docType = 'cni';
  bool _scanned = false;
  bool _loading = false;
  bool _enrichExpanded = false;
  double? _lat;
  double? _lng;
  bool _gpsBusy = false;
  DateTime? _eventDate;
  final List<XFile> _photos = [];
  // Dossier multi-documents : documents supplémentaires déclarés en même
  // temps (ex. portefeuille avec CNI + permis + carte bancaire).
  final List<Map<String, String>> _extraDocs = [];

  bool get _isFound => widget.declarationType == 'found';

  /// Capture la position GPS (F-14), précision réduite à la commune.
  Future<void> _addLocation() async {
    setState(() => _gpsBusy = true);
    final pos = await LocationService.coarsePosition();
    if (!mounted) return;
    setState(() {
      _gpsBusy = false;
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(pos != null
          ? 'Position ajoutée (précision commune).'
          : 'Position indisponible — vérifiez la localisation.'),
    ));
  }

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText:
          _isFound ? 'Date de la découverte' : 'Date de la perte',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 3) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final picked = await MediaService.pickImage(
        source: source, imageQuality: 75, maxWidth: 1200);
    if (!mounted) return;
    if (picked.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(picked.error!),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
      return;
    }
    if (picked.file != null) setState(() => _photos.add(picked.file!));
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _docNumCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  /// Ajoute un document supplémentaire au dossier via un bottom sheet.
  Future<void> _addExtraDoc() async {
    if (1 + _extraDocs.length >= 5) return; // limite dossier (backend: 5)
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController();
    final numCtrl = TextEditingController();
    String docType = 'cni';

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final cs = Theme.of(ctx).colorScheme;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ajouter un document au dossier',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  _isFound
                      ? 'Un autre document trouvé au même endroit.'
                      : 'Un autre document perdu en même temps.',
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _docTypes.keys.map((key) {
                    final selected = docType == key;
                    return ChoiceChip(
                      label: Text(_shortDocLabels[key] ?? key),
                      selected: selected,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : cs.onSurface,
                      ),
                      selectedColor: cs.primary,
                      onSelected: (_) =>
                          setSheetState(() => docType = key),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (_isFound) ...[
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom du propriétaire (sur le document)',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: numCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Numéro du document (optionnel)',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      if (_isFound && nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter au dossier'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (added == true && mounted) {
      setState(() => _extraDocs.add({
            'document_type': docType,
            'owner_name': nameCtrl.text.trim(),
            'document_number': numCtrl.text.trim(),
          }));
    }
    nameCtrl.dispose();
    numCtrl.dispose();
  }

  /// Lance le scanner OCR et pré-remplit les champs + le type de document.
  Future<void> _launchOcr() async {
    final result = await context.push<Map<String, dynamic>>('/ocr/scan');
    if (!mounted || result == null) return;

    setState(() {
      _scanned = true;
      final ln = (result['last_name'] as String?)?.trim() ?? '';
      final fn = (result['first_name'] as String?)?.trim() ?? '';
      final num = (result['document_number'] as String?)?.trim() ?? '';
      final type = result['document_type'] as String?;
      final name = [fn, ln].where((s) => s.isNotEmpty).join(' ').trim();
      if (name.isNotEmpty) _ownerNameCtrl.text = name;
      if (num.isNotEmpty) {
        _docNumCtrl.text = num;
        _enrichExpanded = true; // montre le bonus de précision obtenu
      }
      if (type != null && _docTypes.containsKey(type)) _docType = type;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informations pré-remplies — vérifiez puis validez.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      // Perte : on déclare SON propre document → nom repris du profil.
      // Trouvé : nom lu sur le document (OCR / saisie).
      final ownerName = _isFound
          ? _ownerNameCtrl.text.trim()
          : (ref.read(profileProvider).valueOrNull?.fullName.trim() ?? '');

      final shared = <String, dynamic>{
        'declaration_type': widget.declarationType,
        if (_descriptionCtrl.text.trim().isNotEmpty)
          'description': _descriptionCtrl.text.trim(),
        if (_locationCtrl.text.trim().isNotEmpty)
          'location_description': _locationCtrl.text.trim(),
        if (_lat != null) 'latitude': _lat,
        if (_lng != null) 'longitude': _lng,
        if (_eventDate != null)
          'event_date':
              '${_eventDate!.year}-${_eventDate!.month.toString().padLeft(2, '0')}-${_eventDate!.day.toString().padLeft(2, '0')}',
      };
      final photoPaths = _photos.map((x) => x.path).toList();
      final repo = ref.read(declarationsRepositoryProvider);

      if (_extraDocs.isEmpty) {
        // Déclaration simple (chemin habituel).
        await repo.create({
          ...shared,
          'document_type': _docType,
          if (_docNumCtrl.text.trim().isNotEmpty)
            'document_number': _docNumCtrl.text.trim(),
          if (ownerName.isNotEmpty) 'owner_name': ownerName,
        }, photoPaths: photoPaths);
      } else {
        // Dossier multi-documents : le document principal + les extras.
        // Pour une perte, le propriétaire de chaque document est
        // l'utilisateur lui-même (nom du profil).
        final items = <Map<String, dynamic>>[
          {
            'document_type': _docType,
            if (ownerName.isNotEmpty) 'owner_name': ownerName,
            if (_docNumCtrl.text.trim().isNotEmpty)
              'document_number': _docNumCtrl.text.trim(),
          },
          ..._extraDocs.map((d) => {
                'document_type': d['document_type'],
                if ((_isFound
                        ? d['owner_name']!
                        : ownerName)
                    .isNotEmpty)
                  'owner_name':
                      _isFound ? d['owner_name'] : ownerName,
                if (d['document_number']!.isNotEmpty)
                  'document_number': d['document_number'],
              }),
        ];
        await repo.createBatch(shared, items, photoPaths: photoPaths);
      }
      ref.invalidate(declarationsProvider);
      ref.invalidate(declarationLimitsProvider);

      if (!mounted) return;
      final total = 1 + _extraDocs.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(total > 1
                  ? 'Dossier de $total documents déclaré.'
                  : (_isFound
                      ? 'Document trouvé déclaré.'
                      : 'Perte déclarée.')),
            ),
          ]),
          backgroundColor: Colors.green.shade700,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Enregistrement impossible. Vérifiez votre connexion et réessayez.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profileName =
        ref.watch(profileProvider).valueOrNull?.fullName.trim() ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle déclaration'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: (_isFound ? cs.primary : Colors.orange)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_isFound ? 'Trouvé' : 'Perdu',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isFound ? cs.primary : Colors.orange)),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_isFound) ...[
              // ── Scan OCR : le vrai raccourci du Fast Path ──
              _ScanCard(scanned: _scanned, onTap: _launchOcr),
              const SizedBox(height: 24),
            ] else ...[
              // Perte : on déclare SON propre document.
              _LostIntro(name: profileName),
              const SizedBox(height: 20),
            ],

            // ── 1. Type de document : grille d'icônes, tap direct ──
            Text(
                _isFound
                    ? 'Quel document avez-vous trouvé ?'
                    : 'Quel document avez-vous perdu ?',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.15,
              children: _docTypes.keys.map((key) {
                final selected = _docType == key;
                return Material(
                  color: selected
                      ? cs.primary.withValues(alpha: 0.1)
                      : cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _docType = key);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? cs.primary : cs.outlineVariant,
                          width: selected ? 1.8 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_docIcons[key],
                              size: 26,
                              color: selected
                                  ? cs.primary
                                  : cs.onSurface.withValues(alpha: 0.6)),
                          const SizedBox(height: 6),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(_shortDocLabels[key] ?? key,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: selected
                                        ? cs.primary
                                        : cs.onSurface
                                            .withValues(alpha: 0.75))),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── 2. Nom du propriétaire (prominent) ──
            if (_isFound) ...[
              TextFormField(
                controller: _ownerNameCtrl,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  labelText: 'Nom du propriétaire (sur le document)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),
            ],

            // ── Dossier multi-documents ──
            if (_extraDocs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: cs.primary.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.folder_outlined,
                          size: 20, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                          'Dossier — ${1 + _extraDocs.length} documents',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      'Le document ci-dessus + ceux-ci seront déclarés '
                      'ensemble (un dossier = une seule déclaration active).',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 10),
                    ..._extraDocs.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            Icon(_docIcons[e.value['document_type']],
                                size: 18, color: cs.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_shortDocLabels[e.value['document_type']] ?? e.value['document_type']}'
                                '${(e.value['owner_name'] ?? '').isNotEmpty ? ' — ${e.value['owner_name']}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(
                                  () => _extraDocs.removeAt(e.key)),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    size: 18,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.45)),
                              ),
                            ),
                          ]),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (1 + _extraDocs.length < 5)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addExtraDoc,
                  icon: const Icon(Icons.create_new_folder_outlined,
                      size: 18),
                  label: Text(_extraDocs.isEmpty
                      ? (_isFound
                          ? 'J\'ai trouvé plusieurs documents'
                          : 'J\'ai perdu plusieurs documents')
                      : 'Ajouter un autre document'),
                ),
              ),
            const SizedBox(height: 20),

            // ── Section « Enrichir ma déclaration » (optionnelle) ──
            _EnrichSection(
              expanded: _enrichExpanded,
              onToggle: () =>
                  setState(() => _enrichExpanded = !_enrichExpanded),
              children: [
                TextFormField(
                  controller: _docNumCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Numéro du document',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),
                const _ImpactLabel('🔢 Numéro → +35% de précision de matching'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationCtrl,
                  decoration: InputDecoration(
                    labelText: _isFound
                        ? 'Lieu où vous l\'avez trouvé'
                        : 'Ville / quartier de la perte',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _gpsBusy ? null : _addLocation,
                    icon: _gpsBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            _lat != null
                                ? Icons.check_circle
                                : Icons.my_location_outlined,
                            size: 18,
                            color: _lat != null ? cs.primary : null),
                    label: Text(_lat != null
                        ? 'Position ajoutée'
                        : 'Utiliser ma position'),
                  ),
                ),
                const _ImpactLabel(
                    '📍 Localisation → +20% de précision de matching'),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pickEventDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: _isFound
                          ? 'Date de la découverte'
                          : 'Date de la perte',
                      prefixIcon: const Icon(Icons.event_outlined),
                      suffixIcon:
                          const Icon(Icons.calendar_today_outlined, size: 18),
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(
                      _eventDate != null
                          ? '${_eventDate!.day.toString().padLeft(2, '0')}/${_eventDate!.month.toString().padLeft(2, '0')}/${_eventDate!.year}'
                          : 'Sélectionner…',
                      style: TextStyle(
                        fontSize: 16,
                        color: _eventDate != null
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const _ImpactLabel(
                    '📅 Date → +10% de cohérence de matching'),
                const SizedBox(height: 16),
                // ── Photos (max 3) ──
                Row(children: [
                  ..._photos.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: Image.file(
                                File(e.value.path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color:
                                      cs.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.photo,
                                      color: cs.primary),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _photos.removeAt(e.key)),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: cs.error,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ]),
                      )),
                  if (_photos.length < 3)
                    InkWell(
                      onTap: _addPhoto,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Icon(Icons.add_a_photo_outlined,
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                ]),
                const _ImpactLabel(
                    '📷 Photos (max 3) → identification plus rapide'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description libre',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── 3. CTA principal ──
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: cs.primary,
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_extraDocs.isEmpty
                  ? 'Déclarer'
                  : 'Déclarer le dossier (${1 + _extraDocs.length} documents)'),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Les données sensibles seront masquées automatiquement.',
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Section repliable « Enrichir ma déclaration » — collapsed par défaut.
class _EnrichSection extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  const _EnrichSection({
    required this.expanded,
    required this.onToggle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 20, color: cs.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Enrichir ma déclaration',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('optionnel',
                    style: TextStyle(fontSize: 10, color: cs.primary)),
              ),
              const SizedBox(width: 6),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more,
                    color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ]),
    );
  }
}

/// Impact d'un champ optionnel sur la précision du matching.
class _ImpactLabel extends StatelessWidget {
  final String text;
  const _ImpactLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: cs.primary.withValues(alpha: 0.85))),
    );
  }
}

// ── Encart "déclaration de perte = votre document" ──────────────────────────────
class _LostIntro extends StatelessWidget {
  final String name;
  const _LostIntro({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(Icons.verified_user_outlined, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vous déclarez votre propre document',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: cs.onSurface)),
              const SizedBox(height: 3),
              Text(
                name.isNotEmpty
                    ? 'Propriétaire : $name (repris de votre profil)'
                    : 'Complétez votre profil pour renseigner le propriétaire.',
                style: TextStyle(
                    fontSize: 12.5,
                    color: cs.onSurface.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Carte de scan (raccourci OCR) ───────────────────────────────────────────────
class _ScanCard extends StatelessWidget {
  final bool scanned;
  final VoidCallback onTap;
  const _ScanCard({required this.scanned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: scanned
          ? cs.primary.withValues(alpha: 0.06)
          : cs.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.primary.withValues(alpha: scanned ? 0.4 : 0.55),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  scanned
                      ? Icons.check_circle_rounded
                      : Icons.document_scanner_outlined,
                  size: 24,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanned
                          ? 'Document scanné ✓'
                          : 'Scanner le document (recommandé)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scanned
                          ? 'Appuyez à nouveau pour recommencer.'
                          : 'Les informations sont lues automatiquement.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: cs.onSurface.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
