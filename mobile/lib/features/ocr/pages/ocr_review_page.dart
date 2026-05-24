import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

class OcrReviewPage extends StatefulWidget {
  const OcrReviewPage({super.key});

  @override
  State<OcrReviewPage> createState() => _OcrReviewPageState();
}

class _OcrReviewPageState extends State<OcrReviewPage> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String? _imagePath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra =
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ??
            {};
    _imagePath = extra['imagePath'] as String?;
    final fields = extra['fields'] as Map<String, String>? ?? {};
    _nomCtrl.text = fields['nom'] ?? '';
    _prenomCtrl.text = fields['prenom'] ?? '';
    _numeroCtrl.text = fields['numero'] ?? '';
    _dateCtrl.text = fields['date_naissance'] ?? '';
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _numeroCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    context.pop({
      'nom': _nomCtrl.text,
      'prenom': _prenomCtrl.text,
      'numero': _numeroCtrl.text,
      'date_naissance': _dateCtrl.text,
    });
  }

  @override
  Widget build(BuildContext context) {
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
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_imagePath!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_fix_high,
                      size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vérifiez et corrigez les informations extraites automatiquement.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 16),
            AppTextField(
                label: 'Date de naissance',
                controller: _dateCtrl,
                hint: 'JJ/MM/AAAA',
                keyboardType: TextInputType.datetime),
            const SizedBox(height: 32),
            AppButton(
              label: 'Utiliser ces informations',
              expand: true,
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Recommencer le scan',
              expand: true,
              variant: AppButtonVariant.secondary,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
