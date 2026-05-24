import 'package:flutter/material.dart';
import '../models/declaration.dart';

class DeclarationCard extends StatelessWidget {
  final Declaration declaration;
  final VoidCallback onTap;
  const DeclarationCard(
      {super.key, required this.declaration, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFound = declaration.type == DeclarationType.found;
    final color = isFound ? Colors.green : Colors.orange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isFound ? Icons.search : Icons.help_outline,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(declaration.docTypeLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(declaration.nomProprietaire,
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withOpacity(0.6))),
                if (declaration.lieu != null) ...
                  [
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: cs.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 2),
                      Text(declaration.lieu!,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withOpacity(0.45))),
                    ]),
                  ],
              ],
            ),
          ),
          Chip(
            label: Text(declaration.typeLabel,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
            backgroundColor: color.withOpacity(0.1),
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ]),
      ),
    );
  }
}
