import 'package:flutter/material.dart';

const _labels = {
  'cni': "Carte nationale d'identité",
  'passport': 'Passeport',
  'driving_license': 'Permis de conduire',
  'vehicle_registration': 'Carte grise',
  'birth_certificate': 'Acte de naissance',
  'diploma': 'Diplôme',
  'other': 'Autre',
};

class DocumentTypeDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const DocumentTypeDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Type de document *'),
      items: _labels.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Champ requis' : null,
    );
  }
}

String documentTypeLabel(String key) => _labels[key] ?? key;
