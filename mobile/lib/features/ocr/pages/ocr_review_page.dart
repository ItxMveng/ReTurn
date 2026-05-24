import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/ocr_result.dart';
import '../providers/ocr_notifier.dart';
import '../widgets/sensitive_mask.dart';

/// Écran de revue — l'utilisateur vérifie les données extraites (F-11)
/// Les données sensibles sont masquées par défaut (F-12).
/// Il peut corriger chaque champ avant de valider.
class OcrReviewPage extends ConsumerStatefulWidget {
  const OcrReviewPage({super.key});

  @override
  ConsumerState<OcrReviewPage> createState() => _OcrReviewPageState();
}

class _OcrReviewPageState extends ConsumerState<OcrReviewPage> {
  late TextEditingController _lastNameCtrl;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _docNumCtrl;
  late TextEditingController _expiryCtrl;
  bool _initialized = false;

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _docNumCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  void _initControllers(OcrResult result) {
    if (_initialized) return;
    _lastNameCtrl = TextEditingController(text: result.lastName ?? '');
    _firstNameCtrl = TextEditingController(text: result.firstName ?? '');
    _docNumCtrl = TextEditingController(text: result.documentNumber ?? '');
    _expiryCtrl = TextEditingController(text: result.expiryDate ?? '');
    _initialized = true;
  }

  void _validate(OcrResult result) {
    // Renvoie les données validées/corrigées vers la page de déclaration
    context.pop({
      'last_name': _lastNameCtrl.text.trim(),
      'first_name': _firstNameCtrl.text.trim(),
      'document_number': _docNumCtrl.text.trim(),
      'expiry_date': _expiryCtrl.text.trim(),
      'document_kind': result.kind.name,
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ocrProvider);
    final theme = Theme.of(context);

    if (state is OcrProcessing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is OcrError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Résultat scan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(ocrProvider.notifier).reset();
                    context.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is! OcrSuccess) {
      return const SizedBox.shrink();
    }

    final result = state.result;
    _initControllers(result);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérifier les données'),
        actions: [
          TextButton(
            onPressed: () => _validate(result),
            child: const Text('Utiliser'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Aperçu de l'image scannée ────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              state.image,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Chip(
              label: Text(_kindLabel(result.kind)),
              avatar: const Icon(Icons.badge_outlined, size: 16),
            ),
          ),
          const SizedBox(height: 20),

          // ── Données sensibles masquées (F-12) ────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Données protégées (non transmises)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  SensitiveMask(
                    label: 'Numéro de document',
                    masked: result.maskedDocumentNumber,
                    revealed: result.documentNumber ?? '—',
                  ),
                  const SizedBox(height: 8),
                  SensitiveMask(
                    label: 'Date de naissance',
                    masked: result.maskedBirthDate,
                    revealed: result.birthDate ?? '—',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Champs éditables ─────────────────────────────────
          Text('Champs à utiliser dans la déclaration',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),
          _field('Nom de famille', _lastNameCtrl, Icons.person_outline),
          const SizedBox(height: 12),
          _field('Prénom(s)', _firstNameCtrl, Icons.person_outline),
          const SizedBox(height: 12),
          _field('Numéro de document', _docNumCtrl, Icons.numbers),
          const SizedBox(height: 12),
          _field("Date d'expiration", _expiryCtrl, Icons.calendar_today_outlined),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: () => _validate(result),
            icon: const Icon(Icons.check),
            label: const Text('Valider et remplir le formulaire'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(ocrProvider.notifier).reset();
              context.pop();
            },
            icon: const Icon(Icons.close),
            label: const Text('Ignorer et saisir manuellement'),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  String _kindLabel(DocumentKind kind) => switch (kind) {
    DocumentKind.cni => 'Carte Nationale d\'Identité',
    DocumentKind.passport => 'Passeport',
    DocumentKind.driverLicense => 'Permis de conduire',
    DocumentKind.unknown => 'Document inconnu',
  };
}
