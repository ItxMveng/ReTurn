import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Formulaire de déclaration avec intégration OCR (F-11).
/// Bouton "Scanner" lance OcrScanPage et pré-remplit les champs.
class DeclarationFormPage extends ConsumerStatefulWidget {
  final String declarationType; // 'found' ou 'lost'
  const DeclarationFormPage({super.key, required this.declarationType});

  @override
  ConsumerState<DeclarationFormPage> createState() => _DeclarationFormPageState();
}

class _DeclarationFormPageState extends ConsumerState<DeclarationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _docNumCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _docKind = 'cni';
  bool _loading = false;

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _docNumCtrl.dispose();
    _locationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  /// Lance le scanner OCR et pré-remplit les champs automatiquement
  Future<void> _launchOcr() async {
    final result = await context.push<Map<String, dynamic>>('/ocr/scan');
    if (!mounted || result == null) return;

    setState(() {
      if ((result['last_name'] as String?)?.isNotEmpty == true) {
        _lastNameCtrl.text = result['last_name'] as String;
      }
      if ((result['first_name'] as String?)?.isNotEmpty == true) {
        _firstNameCtrl.text = result['first_name'] as String;
      }
      if ((result['document_number'] as String?)?.isNotEmpty == true) {
        _docNumCtrl.text = result['document_number'] as String;
      }
      if (result['document_kind'] != null) {
        _docKind = result['document_kind'] as String;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Champs pré-remplis par OCR — vérifiez et corrigez si besoin'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // TODO: appel declarationsRepository.create(...)
      context.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFound = widget.declarationType == 'found';
    return Scaffold(
      appBar: AppBar(
        title: Text(isFound ? 'Document trouvé' : 'Document perdu'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Bouton OCR ────────────────────────────────────
            FilledButton.tonalIcon(
              onPressed: _launchOcr,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scanner le document (OCR automatique)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Le scanner lit automatiquement les informations du document '
              'et les remplit dans le formulaire.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 32),

            // ── Type de document ──────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _docKind,
              decoration: const InputDecoration(
                labelText: 'Type de document',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cni', child: Text('Carte Nationale d\'Identité')),
                DropdownMenuItem(value: 'passport', child: Text('Passeport')),
                DropdownMenuItem(value: 'driverLicense', child: Text('Permis de conduire')),
                DropdownMenuItem(value: 'unknown', child: Text('Autre')),
              ],
              onChanged: (v) => setState(() => _docKind = v!),
            ),
            const SizedBox(height: 16),

            // ── Nom / Prénom ──────────────────────────────────
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de famille',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Prénom(s)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Numéro de document ────────────────────────────
            TextFormField(
              controller: _docNumCtrl,
              decoration: const InputDecoration(
                labelText: 'Numéro de document',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Lieu ─────────────────────────────────────────
            TextFormField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                labelText: isFound ? 'Lieu où trouvé' : 'Lieu de perte',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),

            // ── Description libre ─────────────────────────────
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: Text(isFound ? 'Déclarer le document trouvé' : 'Déclarer la perte'),
            ),
          ],
        ),
      ),
    );
  }
}
