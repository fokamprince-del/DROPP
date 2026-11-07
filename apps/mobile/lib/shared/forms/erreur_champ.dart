/// Erreurs de saisie communes à tous les formulaires. Le texte affiché est
/// choisi par l'écran (voir `libelles_erreurs.dart`).
enum ErreurChamp {
  requis,
  telephoneInvalide,
  emailInvalide,
  identifiantInvalide,
  motDePasseTropCourt,
  codeIncomplet,
  numeroCniInvalide,
  dateInvalide,
  dateNaissanceImpossible,
  dateFuture,
  expirationAvantDelivrance,
  carteExpiree,
  naissanceIncoherente,
}

ErreurChamp? validerRequis(String? valeur) =>
    (valeur == null || valeur.trim().isEmpty) ? ErreurChamp.requis : null;
