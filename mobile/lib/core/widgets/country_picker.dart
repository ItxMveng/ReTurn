import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../data/countries.dart';

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i',
  'ï': 'i', 'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'œ': 'oe',
};

String _fold(String s) {
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    buf.write(_accents[ch] ?? ch);
  }
  return buf.toString();
}

/// Feuille de sélection d'un pays (recherche par nom, code ISO ou indicatif).
Future<Country?> showCountryPicker(BuildContext context, {String? selected}) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CountryPickerSheet(selected: selected),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  final String? selected;
  const _CountryPickerSheet({this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final q = _fold(_query.trim());
    final dialQuery = q.replaceAll('+', '');

    final items = kCountries.where((c) {
      if (q.isEmpty) return true;
      return _fold(c.name(lang)).contains(q) ||
          c.code.toLowerCase() == q ||
          (dialQuery.isNotEmpty && c.dial.startsWith(dialQuery));
    }).toList()
      ..sort((a, b) => _fold(a.name(lang)).compareTo(_fold(b.name(lang))));

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: l.countrySearchHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(l.noResults))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final c = items[i];
                        final isSelected = c.code == widget.selected;
                        return ListTile(
                          leading: Text(c.flag,
                              style: const TextStyle(fontSize: 24)),
                          title: Text(c.name(lang)),
                          trailing: isSelected
                              ? Icon(Icons.check, color: cs.primary)
                              : Text('+${c.dial}',
                                  style: TextStyle(
                                      color: cs.onSurface
                                          .withValues(alpha: 0.5))),
                          onTap: () => Navigator.pop(context, c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ « Pays » : affiche le pays choisi et ouvre le sélecteur au toucher.
class CountryField extends StatelessWidget {
  final String? code;
  final String label;
  final ValueChanged<Country> onChanged;
  final bool outlined;

  const CountryField({
    super.key,
    required this.code,
    required this.label,
    required this.onChanged,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final country = countryByCode(code);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final picked = await showCountryPicker(context, selected: code);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.public),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: outlined ? const OutlineInputBorder() : null,
        ),
        child: Text(
          country == null ? '—' : '${country.flag}  ${country.name(lang)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
