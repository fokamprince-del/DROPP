import '../../../utils/telephone.dart';
import 'validateurs.dart';

/// Un email est renvoyé nettoyé ; sinon un téléphone au format international.
/// `null` si ni l'un ni l'autre n'est valide. Le serveur distingue les deux
/// par la présence d'un `@`.
String? normaliserIdentifiant(String saisie) {
  final texte = saisie.trim();
  if (texte.contains('@')) {
    return validerEmailFacultatif(texte) == null ? texte : null;
  }
  return normaliserTelephone(texte);
}

ErreurChamp? validerIdentifiant(String? valeur) {
  if (valeur == null || valeur.trim().isEmpty) return ErreurChamp.requis;
  return normaliserIdentifiant(valeur) == null
      ? ErreurChamp.identifiantInvalide
      : null;
}
