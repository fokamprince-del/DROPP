import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/espacements.dart';
import 'motif_ndop.dart';

/// État vide de la maquette : médaillon ndop, titre, texte et action.
class EtatVide extends StatelessWidget {
  const EtatVide({
    super.key,
    required this.icone,
    required this.titre,
    this.texte,
    this.action,
  });

  final FaIconData icone;
  final String titre;
  final String? texte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schema = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacements.xl,
        vertical: Espacements.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: MotifNdop(
                    hauteur: 120,
                    tailleCase: 20,
                    couleurFonce: schema.primary,
                    couleurClair: schema.surfaceContainerHighest,
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(icone, size: 30, color: schema.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Espacements.l),
          Text(
            titre,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          if (texte != null) ...[
            const SizedBox(height: Espacements.s),
            Text(
              texte!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: schema.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: Espacements.l),
            action!,
          ],
        ],
      ),
    );
  }
}
