import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/declarations_notifier.dart';
import '../../data/repositories/declarations_repository.dart';

class NewDeclarationPage extends ConsumerStatefulWidget {
  const NewDeclarationPage({super.key});

  @override
  ConsumerState<NewDeclarationPage> createState() => _NewDeclarationPageState();
}

class _NewDeclarationPageState extends ConsumerState<NewDeclarationPage> {
  final _formKey = GlobalKey<FormState>();

  // Champs
  String _declarationType = 'found';
  String? _documentType;
  final _docNumberCtrl        = TextEditingController();
  final _ownerNameCtrl        = TextEditingController();
  final _descCtrl             = TextEditingController();
  final _locationCtrl         = TextEditingController();
  DateTime? _eventDate;
  bool _loading = false;

  @override
  void dispose() {
    _docNumberCtrl.dispose();
    _ownerNameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documentType == null) {
      _showError('Choisissez un type de document');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(declarationsRepositoryProvider);
      final decl = await repo.createDeclaration({
        'declaration_type':  _declarationType,
        'document_type':     _documentType!,
        'document_number':   _docNumberCtrl.text.trim().isEmpty ? null : _docNumberCtrl.text.trim(),
        'owner_name':        _ownerNameCtrl.text.trim().isEmpty ? null : _ownerNameCtrl.text.trim(),
        'description':       _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'location_description': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        'event_date':        _eventDate?.toIso8601String().split('T').first,
      });
      if (!mounted) return;
      ref.read(declarationsNotifierProvider.notifier).addItem(decl);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Déclaration créée avec succès'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.goNamed(RouteNames.declarations);
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _eventDate = d);
  }

  @override
  Widget build(BuildContext context) {
    final docTypesAsync = ref.watch(documentTypesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle déclaration'),
        leading: BackButton(onPressed: () => context.goNamed(RouteNames.declarations)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [

            // ── Type de déclaration ───────────────────────────────────────
            const _SectionLabel(label: 'Que souhaitez-vous déclarer ?'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _TypeToggle(
                  label: 'J’ai trouvé un document',
                  icon: Icons.search_rounded,
                  value: 'found',
                  groupValue: _declarationType,
                  onChanged: (v) => setState(() => _declarationType = v),
                )),
                const SizedBox(width: 10),
                Expanded(child: _TypeToggle(
                  label: 'J’ai perdu un document',
                  icon: Icons.report_problem_outlined,
                  value: 'lost',
                  groupValue: _declarationType,
                  onChanged: (v) => setState(() => _declarationType = v),
                )),
              ],
            ),
            const SizedBox(height: 24),

            // ── Type de document ───────────────────────────────────────────
            const _SectionLabel(label: 'Type de document'),
            const SizedBox(height: 10),
            docTypesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Erreur : $e', style: const TextStyle(color: AppColors.error)),
              data: (types) => DropdownButtonFormField<String>(
                initialValue: _documentType,
                hint: const Text('Sélectionner le type'),
                decoration: const InputDecoration(),
                items: types.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setState(() => _documentType = v),
                validator: (v) => v == null ? 'Champ requis' : null,
              ),
            ),
            const SizedBox(height: 20),

            // ── Infos sur le document ──────────────────────────────────────
            const _SectionLabel(label: 'Informations sur le document'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ownerNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom du propriétaire',
                hintText: 'Nom inscrit sur le document',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _docNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Numéro du document',
                hintText: 'Optionnel (peut faciliter le matching)',
                prefixIcon: Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 24),

            // ── Lieu & date ────────────────────────────────────────────────
            const _SectionLabel(label: 'Lieu & date'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Description du lieu',
                hintText: 'Ex : Marché Central de Yaoundé',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date de l’événement',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _eventDate == null
                      ? 'Appuyez pour sélectionner'
                      : '${_eventDate!.day.toString().padLeft(2, '0')}/${_eventDate!.month.toString().padLeft(2, '0')}/${_eventDate!.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _eventDate == null ? AppColors.onSurfaceVariant : AppColors.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Description libre ────────────────────────────────────────────
            const _SectionLabel(label: 'Description (optionnel)'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Décrivez les circonstances, état du document...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Bouton sticky ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Soumettre la déclaration'),
          ),
        ),
      ),
    );
  }
}

// ── Widgets locaux ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant, letterSpacing: 0.3));
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.label, required this.icon, required this.value, required this.groupValue, required this.onChanged});
  final String label;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _selected ? AppColors.primaryContainer : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _selected ? AppColors.primary : AppColors.outline,
            width: _selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: _selected ? AppColors.primary : AppColors.onSurfaceVariant, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selected ? AppColors.primary : AppColors.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
