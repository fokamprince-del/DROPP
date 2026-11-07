import 'package:flutter/material.dart';

import 'couleurs.dart';

/// Couleurs de statut et d'accent qui n'existent pas dans le `ColorScheme`.
@immutable
class CouleursMetier extends ThemeExtension<CouleursMetier> {
  const CouleursMetier({
    required this.succes,
    required this.succesFond,
    required this.attente,
    required this.attenteFond,
    required this.erreur,
    required this.erreurFond,
    required this.accent,
    required this.accentFond,
  });

  final Color succes;
  final Color succesFond;
  final Color attente;
  final Color attenteFond;
  final Color erreur;
  final Color erreurFond;

  /// Hibiscus lisible en texte et en icône.
  final Color accent;
  final Color accentFond;

  static const clair = CouleursMetier(
    succes: Couleurs.plantainTexte,
    succesFond: Couleurs.plantainFond,
    attente: Couleurs.kolaTexte,
    attenteFond: Couleurs.kolaFond,
    erreur: Couleurs.pimentTexte,
    erreurFond: Couleurs.pimentFond,
    accent: Couleurs.hibiscusTexte,
    accentFond: Couleurs.hibiscusFond,
  );

  static const sombre = CouleursMetier(
    succes: Couleurs.plantainTexteSombre,
    succesFond: Couleurs.plantainFondSombre,
    attente: Couleurs.kolaTexteSombre,
    attenteFond: Couleurs.kolaFondSombre,
    erreur: Couleurs.pimentTexteSombre,
    erreurFond: Couleurs.pimentFondSombre,
    accent: Couleurs.hibiscusVif,
    accentFond: Couleurs.hibiscusFondSombre,
  );

  @override
  CouleursMetier copyWith({
    Color? succes,
    Color? succesFond,
    Color? attente,
    Color? attenteFond,
    Color? erreur,
    Color? erreurFond,
    Color? accent,
    Color? accentFond,
  }) => CouleursMetier(
    succes: succes ?? this.succes,
    succesFond: succesFond ?? this.succesFond,
    attente: attente ?? this.attente,
    attenteFond: attenteFond ?? this.attenteFond,
    erreur: erreur ?? this.erreur,
    erreurFond: erreurFond ?? this.erreurFond,
    accent: accent ?? this.accent,
    accentFond: accentFond ?? this.accentFond,
  );

  @override
  CouleursMetier lerp(ThemeExtension<CouleursMetier>? other, double t) {
    if (other is! CouleursMetier) return this;
    return CouleursMetier(
      succes: Color.lerp(succes, other.succes, t)!,
      succesFond: Color.lerp(succesFond, other.succesFond, t)!,
      attente: Color.lerp(attente, other.attente, t)!,
      attenteFond: Color.lerp(attenteFond, other.attenteFond, t)!,
      erreur: Color.lerp(erreur, other.erreur, t)!,
      erreurFond: Color.lerp(erreurFond, other.erreurFond, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentFond: Color.lerp(accentFond, other.accentFond, t)!,
    );
  }
}

extension CouleursMetierContexte on BuildContext {
  CouleursMetier get couleursMetier =>
      Theme.of(this).extension<CouleursMetier>()!;
}
