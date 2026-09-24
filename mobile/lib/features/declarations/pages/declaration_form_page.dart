import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/countries.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/widgets/country_picker.dart';
import '../../../l10n/app_localizations.dart';
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
  'other': 'Autre document',
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

const _kMaxDocs = 5; // taille max d'un dossier (aligné backend)

/// Un document du dossier : un type + un numéro facultatif.
class _DocEntry {
  String type;
  final TextEditingController number;
  _DocEntry(this.type) : number = TextEditingController();
}

/// Déclaration d'un document trouvé/perdu (S-08 / S-09).
///
/// Dossier : une déclaration peut regrouper PLUSIEURS documents de types
/// différents appartenant à la MÊME personne (ex. portefeuille : CNI + permis
/// + carte bancaire). Le propriétaire n'est saisi qu'une seule fois.
class DeclarationFormPage extends ConsumerStatefulWidget {
  final String declarationType; // 'found' ou 'lost'
  const DeclarationFormPage({super.key, required this.declarationType});

  @override
  ConsumerState<DeclarationFormPage> createState() =>
      _DeclarationFormPageState();
}

class _DeclarationFormPageState extends ConsumerState<DeclarationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _ownerCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final List<_DocEntry> _docs = [_DocEntry('cni')];
  bool _scanned = false;
  bool _loading = false;
  double? _lat;
  double? _lng;
  bool _gpsBusy = false;
  DateTime? _eventDate;
  final List<XFile> _photos = [];
  // Pays du lieu de perte/découverte ; par défaut : pays du profil.
  String? _countryCode;

  bool get _isFound => widget.declarationType == 'found';

  String? get _effectiveCountry =>
      _countryCode ??
      ref.read(profileProvider).valueOrNull?.countryCode ??
      deviceCountryCode();

  @override
  void dispose() {
    _ownerCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final d in _docs) {
      d.number.dispose();
    }
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

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
      helpText: _isFound ? 'Date de la découverte' : 'Date de la perte',
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
            title: Text(AppLocalizations.of(context).declTakePhoto),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(AppLocalizations.of(context).declFromGallery),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final picked =
        await MediaService.pickImage(source: source, imageQuality: 75, maxWidth: 1200);
    if (!mounted) return;
    if (picked.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(picked.error!),
          backgroundColor: Theme.of(context).colorScheme.error));
      return;
    }
    if (picked.file != null) setState(() => _photos.add(picked.file!));
  }

  void _addDoc() {
    if (_docs.length >= _kMaxDocs) return;
    HapticFeedback.selectionClick();
    // Propose un type non encore utilisé pour éviter les doublons évidents.
    final used = _docs.map((d) => d.type).toSet();
    final next = _docTypes.keys.firstWhere(
      (k) => !used.contains(k),
      orElse: () => 'other',
    );
    setState(() => _docs.add(_DocEntry(next)));
  }

  void _removeDoc(int i) {
    if (_docs.length <= 1) return;
    setState(() {
      _docs[i].number.dispose();
      _docs.removeAt(i);
    });
  }

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
      if (name.isNotEmpty) _ownerCtrl.text = name;
      if (type != null && _docTypes.containsKey(type)) _docs.first.type = type;
      if (num.isNotEmpty) _docs.first.number.text = num;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).prefilledInfoNotice),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      final ownerName = _isFound
          ? _ownerCtrl.text.trim()
          : (ref.read(profileProvider).valueOrNull?.fullName.trim() ?? '');

      final shared = <String, dynamic>{
        'declaration_type': widget.declarationType,
        if (_descriptionCtrl.text.trim().isNotEmpty)
          'description': _descriptionCtrl.text.trim(),
        if (_locationCtrl.text.trim().isNotEmpty)
          'location_description': _locationCtrl.text.trim(),
        if (_lat != null) 'latitude': _lat,
        if (_lng != null) 'longitude': _lng,
        if (_effectiveCountry != null) 'country_code': _effectiveCountry,
        if (_eventDate != null)
          'event_date':
              '${_eventDate!.year}-${_eventDate!.month.toString().padLeft(2, '0')}-${_eventDate!.day.toString().padLeft(2, '0')}',
      };
      final photoPaths = _photos.map((x) => x.path).toList();
      final repo = ref.read(declarationsRepositoryProvider);

      if (_docs.length == 1) {
        await repo.create({
          ...shared,
          'document_type': _docs.first.type,
          if (_docs.first.number.text.trim().isNotEmpty)
            'document_number': _docs.first.number.text.trim(),
          if (ownerName.isNotEmpty) 'owner_name': ownerName,
        }, photoPaths: photoPaths);
      } else {
        // Dossier : N documents, MÊME propriétaire.
        final items = _docs
            .map((d) => {
                  'document_type': d.type,
                  if (ownerName.isNotEmpty) 'owner_name': ownerName,
                  if (d.number.text.trim().isNotEmpty)
                    'document_number': d.number.text.trim(),
                })
            .toList();
        await repo.createBatch(shared, items, photoPaths: photoPaths);
      }

      ref.invalidate(declarationsProvider);
      ref.invalidate(declarationLimitsProvider);
      if (!mounted) return;
      final n = _docs.length;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(n > 1
                ? '${l.declSubmitDossier} — $n'
                : (_isFound ? l.declSavedFound : l.declSavedLost)),
          ),
        ]),
        backgroundColor: Colors.green.shade700,
      ));
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).declSaveError),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final profileName =
        ref.watch(profileProvider).valueOrNull?.fullName.trim() ?? '';
    final profileCountry = ref.watch(profileProvider).valueOrNull?.countryCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.declFormTitle),
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
                child: Text(_isFound ? l.declTagFound : l.declTagLost,
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
            // ── Bandeau scan (trouvé) ou encart propriétaire (perdu) ──
            if (_isFound)
              _ScanBanner(scanned: _scanned, onTap: _launchOcr)
            else
              _LostOwnerCard(name: profileName),
            const SizedBox(height: 20),

            // ── Propriétaire (trouvé : saisi une fois pour tout le dossier) ──
            if (_isFound) ...[
              _SectionLabel(l.declOwnerLabel),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ownerCtrl,
                textCapitalization: TextCapitalization.words,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: l.declOwnerHint,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.declFieldRequired : null,
              ),
              const SizedBox(height: 22),
            ],

            // ── Documents du dossier (1 propriétaire, N types) ──
            Row(children: [
              Expanded(
                child: _SectionLabel(_docs.length > 1
                    ? '${l.declDossier} (${_docs.length})'
                    : (_isFound ? l.declWhichFound : l.declWhichLost)),
              ),
            ]),
            const SizedBox(height: 8),
            ..._docs.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DocRow(
                    entry: e.value,
                    index: e.key,
                    canRemove: _docs.length > 1,
                    onTypeChanged: (t) => setState(() => e.value.type = t),
                    onRemove: () => _removeDoc(e.key),
                  ),
                )),
            if (_docs.length < _kMaxDocs)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addDoc,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                      _docs.length == 1 ? l.declAddOther : l.declAddMore),
                ),
              ),
            if (_docs.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  l.declSamePerson,
                  style:
                      TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            const SizedBox(height: 22),

            // ── Où et quand ? ──
            _SectionLabel(
                _isFound ? l.declWhereWhenFound : l.declWhereWhenLost),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: _isFound ? l.declPlaceFound : l.declPlaceLost,
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            CountryField(
              code: _countryCode ?? profileCountry ?? deviceCountryCode(),
              label: l.declCountryLabel,
              outlined: true,
              onChanged: (c) => setState(() => _countryCode = c.code),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _gpsBusy ? null : _addLocation,
                  icon: _gpsBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_lat != null ? Icons.check_circle : Icons.my_location_outlined,
                          size: 18, color: _lat != null ? cs.primary : null),
                  label: Text(_lat != null ? l.declPositionAdded : l.declMyPosition),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEventDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_eventDate != null
                      ? '${_eventDate!.day}/${_eventDate!.month}/${_eventDate!.year}'
                      : l.declDate),
                ),
              ),
            ]),
            const SizedBox(height: 22),

            // ── Photos (facultatif) ──
            _SectionLabel(l.declPhotosOptional),
            const SizedBox(height: 8),
            Row(children: [
              ..._photos.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(e.value.path),
                            width: 64, height: 64, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(e.key)),
                          child: Container(
                            decoration: BoxDecoration(
                                color: cs.error, shape: BoxShape.circle),
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
            const SizedBox(height: 22),

            // ── Description libre ──
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l.declDescOptional,
                prefixIcon: const Icon(Icons.notes),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: cs.primary),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_docs.length > 1
                  ? '${l.declSubmitDossier} (${_docs.length})'
                  : (_isFound ? l.declSubmitFound : l.declSubmitLost)),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _isFound ? l.declNoteFound : l.declNoteLost,
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'un document du dossier : menu déroulant stylé (type) + numéro.
class _DocRow extends StatelessWidget {
  final _DocEntry entry;
  final int index;
  final bool canRemove;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onRemove;
  const _DocRow({
    required this.entry,
    required this.index,
    required this.canRemove,
    required this.onTypeChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Row(children: [
            // ── Menu déroulant stylé du type de document ──
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: entry.type,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: cs.primary.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                icon: Icon(Icons.expand_more, color: cs.primary),
                items: _docTypes.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Row(children: [
                            Icon(_docIcons[e.key], size: 18, color: cs.primary),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(AppLocalizations.of(context).docType(e.key),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onTypeChanged(v);
                },
              ),
            ),
            if (canRemove)
              IconButton(
                tooltip: AppLocalizations.of(context).declRemoveDoc,
                onPressed: onRemove,
                icon: Icon(Icons.close, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
              ),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: entry.number,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              isDense: true,
              labelText: AppLocalizations.of(context).declDocNumber,
              helperText: AppLocalizations.of(context).declDocNumberHint,
              prefixIcon: const Icon(Icons.numbers, size: 20),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau « Scanner pour pré-remplir » (déclaration trouvé — S-08).
class _ScanBanner extends StatelessWidget {
  final bool scanned;
  final VoidCallback onTap;
  const _ScanBanner({required this.scanned, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return Material(
      color: cs.primary.withValues(alpha: scanned ? 0.06 : 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: cs.primary.withValues(alpha: scanned ? 0.35 : 0.5),
                width: 1.5),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
              child: Icon(
                  scanned
                      ? Icons.check_circle_rounded
                      : Icons.document_scanner_outlined,
                  color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scanned ? l.declScanned : l.declScanStep,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scanned ? l.declScanRedo : l.declScanHint,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
          ]),
        ),
      ),
    );
  }
}

/// Encart « Vous déclarez votre propre document » (déclaration perdu — S-09).
class _LostOwnerCard extends StatelessWidget {
  final String name;
  const _LostOwnerCard({required this.name});

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
              Text(AppLocalizations.of(context).declOwnLostTitle,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
            color: cs.onSurface.withValues(alpha: 0.55)));
  }
}
