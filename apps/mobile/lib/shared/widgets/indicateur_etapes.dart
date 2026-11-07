import 'package:flutter/material.dart';

import '../../core/l10n/contexte_l10n.dart';
import '../theme/couleurs_metier.dart';
import '../theme/espacements.dart';

/// « Étape 2 sur 4 » : le texte porte l'information, les barres l'illustrent
/// (faites en couleur de marque, en cours en hibiscus, à venir en gris).
class IndicateurEtapes extends StatelessWidget {
  const IndicateurEtapes({super.key, required this.etape, required this.total});

  final int etape;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = context.couleursMetier.accent;
    final libelle = context.l10n.etapeSur(etape, total);

    Color couleur(int i) {
      if (i < etape) return theme.colorScheme.primary;
      if (i == etape) return accent;
      return theme.colorScheme.outlineVariant;
    }

    return Semantics(
      container: true,
      label: libelle,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 1; i <= total; i++) ...[
                  if (i > 1) const SizedBox(width: Espacements.xs),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: couleur(i),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: Espacements.s),
            Text(
              libelle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
