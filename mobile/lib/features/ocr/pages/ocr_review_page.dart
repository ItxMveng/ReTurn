import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/ocr_result.dart';
import '../providers/ocr_notifier.dart';

class OcrReviewPage extends ConsumerStatefulWidget {
  const OcrReviewPage({super.key});

  @override
  ConsumerState<OcrReviewPage> createState() => _OcrReviewPageState();
}

class _OcrReviewPageState extends ConsumerState<OcrReviewPage> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  bool _populated = false;
  DocumentKind _kind = DocumentKind.unknown;

  @override
  void initState() {
    super.initState();
    // Met à jour l'aperçu du masquage quand le numéro est corrigé.
    _numeroCtrl.addListener(() => setState(() {}));
  }

  /// Aperçu public du numéro (F-12) : "123456789" → "*****6789".
  String get _maskedNumero {
    final n = _numeroCtrl.text.trim();
    if (n.length < 4) return '****';
    return '${'*' * (n.length - 4)}${n.substring(n.length - 4)}';
  }

  static const _kindLabels = <DocumentKind, String>{
    DocumentKind.cni: 'Carte nationale d\'identité',
    DocumentKind.passport: 'Passeport',
    DocumentKind.driverLicense: 'Permis de conduire',
    DocumentKind.birthCertificate: 'Acte de naissance',
    DocumentKind.diploma: 'Diplôme',
    DocumentKind.vehicleRegistration: 'Carte grise',
    DocumentKind.other: 'Autre document',
    DocumentKind.unknown: 'Type non détecté',
  };

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _numeroCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _populateFromOcr(OcrSuccess s) {
    if (_populated) return;
    _populated = true;
    _nomCtrl.text = s.result.lastName ?? '';
    _prenomCtrl.text = s.result.firstName ?? '';
    _numeroCtrl.text = s.result.documentNumber ?? '';
    _dateCtrl.text = s.result.birthDate ?? '';
    _kind = s.result.kind;
  }

  void _confirm() {
    // Clés alignées sur le formulaire de déclaration (+ type de doc auto).
    context.pop({
      'last_name': _nomCtrl.text.trim(),
      'first_name': _prenomCtrl.text.trim(),
      'document_number': _numeroCtrl.text.trim(),
      'birth_date': _dateCtrl.text.trim(),
      'document_type': _kind.backendType,
    });
  }

  @override
  Widget build(BuildContext context) {
    final ocrState = ref.watch(ocrProvider);
    final success = ocrState is OcrSuccess ? ocrState : null;

    if (success != null) _populateFromOcr(success);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérifier les informations'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (success?.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  success!.image,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            // Bandeau d'info : invite à vérifier les informations lues
            _ExtractionBanner(
              isEmpty: success?.result.isEmpty ?? true,
            ),
            const SizedBox(height: 16),

            // ── Type détecté (wireframe) ──────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outline),
              ),
              child: Row(children: [
                const Icon(Icons.badge_outlined,
                    size: 20, color: AppColors.kGreenDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _kindLabels[_kind] ?? 'Type non détecté',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                      _kind == DocumentKind.unknown
                          ? 'À vérifier'
                          : 'Détecté',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimaryContainer)),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            AppTextField(
                label: 'Nom', controller: _nomCtrl, hint: 'Ex: MBARGA'),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Prénom',
                controller: _prenomCtrl,
                hint: 'Ex: Jean-Pierre'),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Numéro du document',
                controller: _numeroCtrl,
                hint: 'Ex: CM-123456789',
                keyboardType: TextInputType.text),
            if (_numeroCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.lock_outline,
                    size: 13, color: AppColors.onSurfaceVariant),
                const SizedBox(width: 5),
                Text('Affichage public : $_maskedNumero',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.onSurfaceVariant)),
              ]),
            ],
            const SizedBox(height: 16),
            AppTextField(
                label: 'Date de naissance',
                controller: _dateCtrl,
                hint: 'JJ/MM/AAAA',
                keyboardType: TextInputType.datetime),
            const SizedBox(height: 32),
            AppButton(
              label: 'Confirmer les informations',
              expand: true,
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Reprendre la photo',
              expand: true,
              variant: AppButtonVariant.secondary,
              onPressed: () {
                ref.read(ocrProvider.notifier).reset();
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtractionBanner extends StatelessWidget {
  final bool isEmpty;
  const _ExtractionBanner({required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    // Wireframe : bannière IA vert foncé en cas de succès, orange sinon.
    if (isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 18, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Lecture incomplète. Complétez les champs ci-dessous à la main.',
                style: TextStyle(fontSize: 12, color: AppColors.onSurface),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14331F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 18, color: Color(0xFF4FCFD6)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Extraction IA réussie — vérifiez et corrigez si besoin.',
              style: TextStyle(fontSize: 12, color: Color(0xFFB7F7C8)),
            ),
          ),
        ],
      ),
    );
  }
}
