import 'package:flutter/material.dart';

import 'couleurs_metier.dart';

/// Lien d'action en hibiscus (texte lisible : 5,5:1 minimum).
ButtonStyle lienAccent(BuildContext context) =>
    TextButton.styleFrom(foregroundColor: context.couleursMetier.accent);

/// Bouton à contour hibiscus, pour une action secondaire mise en valeur.
ButtonStyle boutonContourAccent(BuildContext context) {
  final accent = context.couleursMetier.accent;
  return OutlinedButton.styleFrom(
    foregroundColor: accent,
    side: BorderSide(color: accent),
  );
}
