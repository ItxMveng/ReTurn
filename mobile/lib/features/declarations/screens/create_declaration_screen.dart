import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../application/declarations_notifier.dart';

class CreateDeclarationScreen extends ConsumerStatefulWidget {
  const CreateDeclarationScreen({super.key});

  @override
  ConsumerState<CreateDeclarationScreen> createState() =>
      _CreateDeclarationScreenState();
}

class _CreateDeclarationScreenState
    extends ConsumerState<CreateDeclarationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'found';
  String _docType = 'cni';
  final _ownerNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _loading = false;

  final _docTypes = ['cni', 'passport', 'permis', 'carte_scolaire', 'autre'];

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(declarationsNotifierProvider.notifier).create({
        'declaration_type': _type,
        'document_type': _docType,
        'owner_name': _ownerNameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location_name': _locationCtrl.text.trim(),
      });
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'found', label: Text("J'ai trouvé")),
                  ButtonSegment(value: 'lost', label: Text("J'ai perdu")),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _docType,
                decoration: const InputDecoration(
                  labelText: 'Type de document',
                  border: OutlineInputBorder(),
                ),
                items: _docTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _docType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du propriétaire',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lieu (ex: Marché Mokolo, Yaoundé)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description complémentaire',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Publier la déclaration'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
