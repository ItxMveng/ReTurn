import 'package:flutter/material.dart';

/// Widget F-12 — Affiche une donnée sensible masquée avec option "révéler"
/// Utilisé pour le numéro de document et la date de naissance sur l'écran de revue OCR.
class SensitiveMask extends StatefulWidget {
  final String masked;    // Valeur masquée (ex: ****6789)
  final String revealed;  // Valeur réelle (jamais envoyée à l'API)
  final String label;

  const SensitiveMask({
    super.key,
    required this.masked,
    required this.revealed,
    required this.label,
  });

  @override
  State<SensitiveMask> createState() => _SensitiveMaskState();
}

class _SensitiveMaskState extends State<SensitiveMask> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _revealed ? widget.revealed : widget.masked,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: _revealed ? 0 : 2,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: _revealed ? 'Masquer' : 'Révéler temporairement',
          icon: Icon(
            _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 18,
          ),
          onPressed: () => setState(() => _revealed = !_revealed),
        ),
      ],
    );
  }
}
