import '../../../utils/telephone.dart';

enum ErreurChamp {
  requis,
  telephoneInvalide,
  emailInvalide,
  identifiantInvalide,
  motDePasseTropCourt,
  codeIncomplet,
}

const longueurMinMotDePasse = 8;
const longueurCode = 6;

ErreurChamp? validerRequis(String? valeur) =>
    (valeur == null || valeur.trim().isEmpty) ? ErreurChamp.requis : null;

ErreurChamp? validerTelephone(String? valeur) {
  if (valeur == null || valeur.trim().isEmpty) return ErreurChamp.requis;
  return normaliserTelephone(valeur) == null
      ? ErreurChamp.telephoneInvalide
      : null;
}

/// Facultatif : vide = valide.
ErreurChamp? validerEmailFacultatif(String? valeur) {
  final email = valeur?.trim() ?? '';
  if (email.isEmpty) return null;
  final valide =
      email.length <= 254 &&
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  return valide ? null : ErreurChamp.emailInvalide;
}

/// Les espaces comptent dans un mot de passe : pas de `trim`.
ErreurChamp? validerNouveauMotDePasse(String? valeur) {
  if (valeur == null || valeur.isEmpty) return ErreurChamp.requis;
  return valeur.length < longueurMinMotDePasse
      ? ErreurChamp.motDePasseTropCourt
      : null;
}

ErreurChamp? validerCode(String? valeur) {
  if (valeur == null || valeur.isEmpty) return ErreurChamp.requis;
  return RegExp(r'^\d{6}$').hasMatch(valeur) ? null : ErreurChamp.codeIncomplet;
}

/// Force de 0 à 4 (les 4 barres de la maquette). Indicatif seulement : c'est
/// le serveur qui fait foi (8 caractères minimum).
int forceMotDePasse(String motDePasse) {
  if (motDePasse.isEmpty) return 0;
  var points = 0;
  if (motDePasse.length >= longueurMinMotDePasse) points++;
  if (motDePasse.length >= 12) points++;
  final lettres = RegExp('[A-Za-zÀ-ÿ]').hasMatch(motDePasse);
  if (lettres && RegExp(r'\d').hasMatch(motDePasse)) points++;
  final majMin =
      RegExp('[A-ZÀ-Þ]').hasMatch(motDePasse) &&
      RegExp('[a-zß-ÿ]').hasMatch(motDePasse);
  if (majMin || RegExp(r'[^\w\s]').hasMatch(motDePasse)) points++;
  return points;
}
