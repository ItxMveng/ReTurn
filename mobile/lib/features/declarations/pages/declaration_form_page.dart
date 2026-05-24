import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/declaration.dart';
import '../repositories/declarations_repository.dart';
import '../providers/declarations_provider.dart';

class DeclarationFormPage extends ConsumerStatefulWidget {
  const DeclarationFormPage({super.key});
  @override
  ConsumerState<DeclarationFormPage> createState() =>
      _DeclarationFormPageState();
}

class _DeclarationFormPageState
    extends ConsumerState<DeclarationFormPage> {
  final _formKey = GlobalKey<FormState>();
  DeclarationType _type = DeclarationType.found;
  DocType _docType = DocType.cni;
  final _nomCtr = TextEditingController();
  final _lieuCtr = TextEditingController();
  final _descCtr = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nomCtr.dispose();
    _lieuCtr.dispose();
    _descCtr.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(declarationsRepositoryProvider);
      await repo.create({
        'type': _type.name,
        'doc_type': _docType.name,
        'nom_proprietaire': _nomCtr.text.trim(),
        'lieu': _lieuCtr.text.trim(),
        'description': _descCtr.text.trim(),
      });
      ref.invalidate(declarationsProvider);
      if (mounted) context.go('/declarations');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle déclaration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type de déclaration',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              SegmentedButton<DeclarationType>(
                segments: const [
                  ButtonSegment(
                      value: DeclarationType.found,
                      label: Text('Trouvé'),
                      icon: Icon(Icons.search)),
                  ButtonSegment(
                      value: DeclarationType.lost,
                      label: Text('Perdu'),
                      icon: Icon(Icons.help_outline)),
                ],
                selected: {_type},
                onSelectionChanged: (s) =>
                    setState(() => _type = s.first),
              ),
              const SizedBox(height: 20),
              const Text('Type de document',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<DocType>(
                value: _docType,
                decoration: const InputDecoration(),
                items: DocType.values
                    .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(_docTypeLabel(d))))
                    .toList(),
                onChanged: (v) => setState(() => _docType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomCtr,
                decoration: const InputDecoration(
                    labelText: 'Nom du propriétaire'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lieuCtr,
                decoration: const InputDecoration(
                    labelText: 'Lieu (optionnel)',
                    prefixIcon: Icon(Icons.location_on_outlined)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtr,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    alignLabelWithHint: true),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Publier la déclaration'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _docTypeLabel(DocType d) {
    switch (d) {
      case DocType.cni: return 'CNI';
      case DocType.passeport: return 'Passeport';
      case DocType.permis: return 'Permis de conduire';
      case DocType.diplome: return 'Diplôme';
      case DocType.autre: return 'Autre';
    }
  }
}
