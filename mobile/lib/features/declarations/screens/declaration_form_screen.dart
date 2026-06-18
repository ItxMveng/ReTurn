import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:return_mobile/core/theme/app_theme.dart';
import 'package:return_mobile/features/declarations/providers/declaration_provider.dart';
import 'package:return_mobile/features/declarations/services/ocr_service.dart';
import 'package:return_mobile/features/profile/providers/profile_provider.dart';
import 'package:return_mobile/l10n/app_localizations.dart';
import 'package:return_mobile/shared/widgets/document_type_dropdown.dart';

class DeclarationFormScreen extends ConsumerStatefulWidget {
  final String declarationType; // "found" | "lost"
  const DeclarationFormScreen({super.key, required this.declarationType});

  @override
  ConsumerState<DeclarationFormScreen> createState() =>
      _DeclarationFormScreenState();
}

class _DeclarationFormScreenState extends ConsumerState<DeclarationFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _docNumberCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationDescCtrl = TextEditingController();

  String? _selectedDocumentType;
  final List<File> _photos = [];
  double? _latitude;
  double? _longitude;
  bool _loadingOcr = false;
  bool _loadingLocation = false;
  bool _submitting = false;
  bool _profileChecked = false;
  Set<String> _autoFilledFields = {};

  // For the "scan" success animation
  late AnimationController _scanAnim;
  late Animation<double> _scanFade;

  final _ocr = OcrService();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _scanFade = CurvedAnimation(parent: _scanAnim, curve: Curves.easeOut);

    if (widget.declarationType == 'lost') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initForLost());
    }
  }

  void _initForLost() {
    final profileAsync = ref.read(profileProvider);
    // Si le profil charge encore, attendre
    if (profileAsync.isLoading) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _initForLost();
      });
      return;
    }
    final profile = profileAsync.valueOrNull;
    if (profile == null) {
      // Profil non chargé : permettre quand même la saisie manuelle
      setState(() => _profileChecked = true);
      return;
    }
    if (!profile.isProfileComplete) {
      _showProfileIncompleteDialog();
      return;
    }
    if (profile.fullName.isNotEmpty) {
      _ownerNameCtrl.text = profile.fullName;
    }
    setState(() => _profileChecked = true);
  }

  void _showProfileIncompleteDialog() {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l.profileIncompleteTitle),
        content: Text(l.profileIncompleteDesc),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (context.canPop()) context.pop();
            },
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/profile/setup');
            },
            child: Text(l.profileCompleteNow),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _docNumberCtrl.dispose();
    _ownerNameCtrl.dispose();
    _descCtrl.dispose();
    _locationDescCtrl.dispose();
    _scanAnim.dispose();
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final xFile = await _picker.pickImage(
      source: source, imageQuality: 85, maxWidth: 1920,
    );
    if (xFile == null) return;
    final file = File(xFile.path);
    setState(() {
      if (_photos.length < 3) _photos.add(file);
      if (widget.declarationType == 'found') _loadingOcr = true;
    });

    if (widget.declarationType != 'found') return;

    try {
      final result = await _ocr.extractFromFile(file);
      if (!mounted) return;
      bool anyFilled = false;

      if (result.documentNumber != null && _docNumberCtrl.text.isEmpty) {
        _docNumberCtrl.text = result.documentNumber!;
        anyFilled = true;
      }
      final name = result.bestOwnerName;
      if (name != null && _ownerNameCtrl.text.isEmpty) {
        _ownerNameCtrl.text = name;
        anyFilled = true;
      }
      if (result.detectedDocumentType != null &&
          _selectedDocumentType == null) {
        _selectedDocumentType = result.detectedDocumentType;
        anyFilled = true;
      }

      setState(() {
        _autoFilledFields = result.autoFilledFields;
        _loadingOcr = false;
      });

      if (anyFilled) {
        _scanAnim.forward(from: 0);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _scanAnim.reverse();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingOcr = false);
    }
  }

  void _removePhoto(int i) {
    setState(() {
      _photos.removeAt(i);
      if (_photos.isEmpty) _autoFilledFields = {};
    });
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Localisation refusée définitivement')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() { _latitude = pos.latitude; _longitude = pos.longitude; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur GPS: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDocumentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un type de document')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(declarationListProvider.notifier).create(
            declarationType: widget.declarationType,
            documentType: _selectedDocumentType!,
            documentNumber: _docNumberCtrl.text.trim().isEmpty
                ? null : _docNumberCtrl.text.trim(),
            ownerName: _ownerNameCtrl.text.trim().isEmpty
                ? null : _ownerNameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null : _descCtrl.text.trim(),
            latitude: _latitude,
            longitude: _longitude,
            locationDescription: _locationDescCtrl.text.trim().isEmpty
                ? null : _locationDescCtrl.text.trim(),
            photoPaths: _photos.map((f) => f.path).toList(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Déclaration enregistrée !'),
            backgroundColor: Colors.green,
          ),
        );
        // pop vers la liste (avec bouton retour fonctionnel)
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/declarations');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isFound = widget.declarationType == 'found';
    final isLostOwnerReadOnly = !isFound && _profileChecked;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFound ? l.declarationFoundTitle : l.declarationLostTitle),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              if (isFound) ...[
                // ── SCAN ZONE ─────────────────────────────────────────
                _ScanZone(
                  photos: _photos,
                  loading: _loadingOcr,
                  autoFilledFields: _autoFilledFields,
                  scanFade: _scanFade,
                  onPickCamera: () => _pickPhoto(ImageSource.camera),
                  onPickGallery: () => _pickPhoto(ImageSource.gallery),
                  onRemove: _removePhoto,
                ),
                const SizedBox(height: 24),
              ],

              // ── OCR banner (found only, when fields were filled) ────
              if (isFound && _autoFilledFields.isNotEmpty) ...[
                FadeTransition(
                  opacity: _scanFade,
                  child: _OcrBanner(fields: _autoFilledFields),
                ),
                const SizedBox(height: 16),
              ],

              // ── Document type ─────────────────────────────────────
              const _SectionLabel('Type de document *'),
              DocumentTypeDropdown(
                value: _selectedDocumentType,
                onChanged: (v) => setState(() => _selectedDocumentType = v),
              ),
              const SizedBox(height: 16),

              // ── Document number ───────────────────────────────────
              _AutoFilledField(
                controller: _docNumberCtrl,
                label: 'Numéro du document',
                icon: Icons.numbers_outlined,
                autoFilled: _autoFilledFields.contains('documentNumber'),
                loading: _loadingOcr,
              ),
              const SizedBox(height: 16),

              // ── Owner name ────────────────────────────────────────
              _AutoFilledField(
                controller: _ownerNameCtrl,
                label: 'Nom du titulaire',
                icon: Icons.person_outline,
                autoFilled: _autoFilledFields.contains('ownerName'),
                readOnly: isLostOwnerReadOnly,
                lockedTooltip: isLostOwnerReadOnly
                    ? 'Pré-rempli depuis votre profil' : null,
              ),
              const SizedBox(height: 16),

              // ── Description ───────────────────────────────────────
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (contexte, état…)',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: Icon(Icons.notes_outlined),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // ── Lost: photo optional ──────────────────────────────
              if (!isFound) ...[
                const _SectionLabel('Photo du document (optionnel)'),
                _SimplePhotoPicker(
                  photos: _photos,
                  loading: false,
                  onPickCamera: () => _pickPhoto(ImageSource.camera),
                  onPickGallery: () => _pickPhoto(ImageSource.gallery),
                  onRemove: _removePhoto,
                ),
                const SizedBox(height: 20),
              ],

              // ── Location ──────────────────────────────────────────
              const _SectionLabel('Localisation'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationDescCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lieu (ex: Marché Mokolo, Yaoundé)',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton.filled(
                      onPressed: _loadingLocation ? null : _getLocation,
                      icon: _loadingLocation
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.my_location),
                      tooltip: 'Obtenir ma position GPS',
                    ),
                  ),
                ],
              ),
              if (_latitude != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: kGreenDark),
                  ),
                ),
              const SizedBox(height: 32),

              // ── Submit ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(isFound
                          ? Icons.upload_outlined
                          : Icons.report_outlined),
                  label: Text(isFound
                      ? 'Soumettre le document trouvé'
                      : 'Déclarer la perte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scan Zone (found declarations) ───────────────────────────────────────────

class _ScanZone extends StatelessWidget {
  final List<File> photos;
  final bool loading;
  final Set<String> autoFilledFields;
  final Animation<double> scanFade;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final void Function(int) onRemove;

  const _ScanZone({
    required this.photos,
    required this.loading,
    required this.autoFilledFields,
    required this.scanFade,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPhoto = photos.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Scanner le document *'),
        const SizedBox(height: 8),

        // Main photo preview / tap zone
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = (w * 10 / 16).clamp(180.0, 280.0);
            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: hasPhoto
                          ? Colors.transparent
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: hasPhoto
                          ? null
                          : Border.all(
                              color: kGreen.withValues(alpha: 0.3),
                              width: 1.5,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: hasPhoto
                          ? Image.file(photos[0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity)
                          : const _EmptyPhotoHint(),
                    ),
                  ),
                  // OCR scanning overlay
                  if (loading)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const _ScanningOverlay(),
                    ),
                  // Action buttons (bottom of image)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _PhotoActionBtn(
                            icon: Icons.camera_alt_outlined,
                            label: 'Caméra',
                            onTap: loading || photos.length >= 3
                                ? null
                                : onPickCamera,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PhotoActionBtn(
                            icon: Icons.photo_library_outlined,
                            label: 'Galerie',
                            onTap: loading || photos.length >= 3
                                ? null
                                : onPickGallery,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Success badge when OCR ran
                  if (autoFilledFields.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FadeTransition(
                        opacity: scanFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: kGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('IA analysée',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Thumbnail strip for extra photos
        if (photos.length > 1) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(photos[i],
                        width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (photos.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (photos.length < 3) ...[
                TextButton.icon(
                  onPressed: loading ? null : onPickCamera,
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: Text('Ajouter (${photos.length}/3)'),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4)),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: () => onRemove(0),
                icon: const Icon(Icons.delete_outline, size: 16,
                    color: Color(0xFFEF4444)),
                label: const Text('Supprimer',
                    style: TextStyle(color: Color(0xFFEF4444))),
                style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmptyPhotoHint extends StatelessWidget {
  const _EmptyPhotoHint();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: kGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.document_scanner_outlined,
              color: kGreen, size: 32),
        ),
        const SizedBox(height: 12),
        const Text(
          'Photographier ou téléverser le document',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'L\'IA remplira automatiquement les champs',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ScanningOverlay extends StatefulWidget {
  const _ScanningOverlay();

  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pos;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pos = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black38,
      child: Stack(
        children: [
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: kGreen, strokeWidth: 3),
                SizedBox(height: 12),
                Text('Analyse IA en cours…',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ],
            ),
          ),
          // Scan line
          AnimatedBuilder(
            animation: _pos,
            builder: (_, __) => Positioned(
              top: _pos.value * 200,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.transparent,
                    kGreen.withValues(alpha: 0.8),
                    Colors.transparent
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PhotoActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── OCR result banner ─────────────────────────────────────────────────────────

class _OcrBanner extends StatelessWidget {
  final Set<String> fields;
  const _OcrBanner({required this.fields});

  static const _labels = {
    'documentNumber': 'Numéro',
    'ownerName': 'Titulaire',
    'dateOfBirth': 'Date de naissance',
  };

  @override
  Widget build(BuildContext context) {
    final filled = fields
        .where((f) => _labels.containsKey(f))
        .map((f) => _labels[f]!)
        .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: kGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pré-rempli automatiquement : $filled',
              style: const TextStyle(
                  color: kGreenDark, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Auto-filled field ─────────────────────────────────────────────────────────

class _AutoFilledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool autoFilled;
  final bool loading;
  final bool readOnly;
  final String? lockedTooltip;

  const _AutoFilledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.autoFilled = false,
    this.loading = false,
    this.readOnly = false,
    this.lockedTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget? suffix;
    if (loading) {
      suffix = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (readOnly && lockedTooltip != null) {
      suffix = Tooltip(
        message: lockedTooltip!,
        child: const Icon(Icons.lock_outline, size: 18),
      );
    } else if (autoFilled) {
      suffix = const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.auto_awesome, color: kGreen, size: 18),
      );
    }

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: readOnly || autoFilled,
        fillColor: readOnly
            ? cs.onSurface.withValues(alpha: 0.06)
            : autoFilled
                ? kGreen.withValues(alpha: 0.05)
                : null,
        enabledBorder: autoFilled
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: kGreen.withValues(alpha: 0.4), width: 1.5),
              )
            : null,
      ),
    );
  }
}

// ── Simple photo picker (for lost declarations) ───────────────────────────────

class _SimplePhotoPicker extends StatelessWidget {
  final List<File> photos;
  final bool loading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final void Function(int) onRemove;

  const _SimplePhotoPicker({
    required this.photos,
    required this.loading,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: loading || photos.length >= 3 ? null : onPickCamera,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Caméra'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: loading || photos.length >= 3 ? null : onPickGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galerie'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(photos[i],
                        width: 80, height: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      );
}
