import 'package:flutter/foundation.dart';

import '../../../shared/forms/erreur_champ.dart';
import '../data/modeles_kyc.dart';

enum ChampCni { nom, prenom, numero, naissance, lieu, delivrance, expiration }

/// En dessous, on invite à vérifier avec plus d'attention. Indication
/// d'interface, pas une règle métier.
const seuilConfianceBasse = 70;

/// `JJ/MM/AAAA` → jour UTC ; `null` si le format ou le jour est impossible.
DateTime? analyserDateSaisie(String? saisie) {
  if (saisie == null) return null;
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(saisie.trim());
  if (m == null) return null;
  final jour = int.parse(m[1]!);
  final mois = int.parse(m[2]!);
  final annee = int.parse(m[3]!);
  final date = DateTime.utc(annee, mois, jour);
  final coherent = date.day == jour && date.month == mois && date.year == annee;
  return coherent ? date : null;
}

String formaterJour(DateTime jour) =>
    '${jour.day.toString().padLeft(2, '0')}/'
    '${jour.month.toString().padLeft(2, '0')}/'
    '${jour.year.toString().padLeft(4, '0')}';

DateTime _jour(DateTime t) => DateTime.utc(t.year, t.month, t.day);

bool _vide(String? v) => v == null || v.trim().isEmpty;

ErreurChamp? validerNumeroCni(String? valeur) {
  if (_vide(valeur)) return ErreurChamp.requis;
  return numeroCniValide(normaliserNumeroCni(valeur!))
      ? null
      : ErreurChamp.numeroCniInvalide;
}

ErreurChamp? validerDateNaissance(String? valeur, {DateTime? aujourdhui}) {
  if (_vide(valeur)) return ErreurChamp.requis;
  final date = analyserDateSaisie(valeur);
  if (date == null) return ErreurChamp.dateInvalide;
  final limite = _jour(aujourdhui ?? DateTime.now());
  if (date.isAfter(limite) || date.year < 1900) {
    return ErreurChamp.dateNaissanceImpossible;
  }
  return null;
}

ErreurChamp? validerDateDelivrance(String? valeur, {DateTime? aujourdhui}) {
  if (_vide(valeur)) return ErreurChamp.requis;
  final date = analyserDateSaisie(valeur);
  if (date == null || date.year < 1900) return ErreurChamp.dateInvalide;
  if (date.isAfter(_jour(aujourdhui ?? DateTime.now()))) {
    return ErreurChamp.dateFuture;
  }
  return null;
}

ErreurChamp? validerDateExpiration(String? valeur, String? delivrance) {
  if (_vide(valeur)) return ErreurChamp.requis;
  final date = analyserDateSaisie(valeur);
  if (date == null) return ErreurChamp.dateInvalide;
  final debut = analyserDateSaisie(delivrance);
  if (debut != null && !date.isAfter(debut)) {
    return ErreurChamp.expirationAvantDelivrance;
  }
  return null;
}

/// `true` si la date est valide et déjà passée. Un avertissement, pas un refus.
bool carteExpiree(String? expiration, {DateTime? aujourdhui}) {
  final date = analyserDateSaisie(expiration);
  if (date == null) return false;
  return date.isBefore(_jour(aujourdhui ?? DateTime.now()));
}

/// Valeurs saisies, sous forme de texte : ce que l'utilisateur voit et corrige.
@immutable
class FormulaireCni {
  const FormulaireCni({this.valeurs = const {}});

  factory FormulaireCni.depuisDonnees(DonneesCni donnees) =>
      FormulaireCni(valeurs: valeursLues(donnees));

  final Map<ChampCni, String> valeurs;

  String valeur(ChampCni champ) => valeurs[champ] ?? '';

  bool get vide => ChampCni.values.every((c) => valeur(c).trim().isEmpty);

  FormulaireCni avec(ChampCni champ, String valeur) =>
      FormulaireCni(valeurs: {...valeurs, champ: valeur});

  /// Champs effectivement reconnus (texte non vide, date valide).
  static Map<ChampCni, String> valeursLues(DonneesCni d) {
    String? texte(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    final numero = texte(d.numeroCni);
    return {
      ChampCni.nom: ?texte(d.nomLegal),
      ChampCni.prenom: ?texte(d.prenomLegal),
      if (numero != null) ChampCni.numero: normaliserNumeroCni(numero),
      if (d.dateNaissance case final j?) ChampCni.naissance: formaterJour(j),
      ChampCni.lieu: ?texte(d.lieuNaissance),
      if (d.dateEtablissement case final j?)
        ChampCni.delivrance: formaterJour(j),
      if (d.dateExpiration case final j?) ChampCni.expiration: formaterJour(j),
    };
  }

  /// Remplit seulement les champs reconnus : ce que l'utilisateur avait tapé
  /// et qui n'a pas été lu reste intact.
  FormulaireCni avecExtraction(DonneesCni donnees) =>
      FormulaireCni(valeurs: {...valeurs, ...valeursLues(donnees)});

  /// `null` tant qu'une date est illisible : à utiliser après validation.
  DonneesCni? versDonnees() {
    final naissance = analyserDateSaisie(valeur(ChampCni.naissance));
    final delivrance = analyserDateSaisie(valeur(ChampCni.delivrance));
    final expiration = analyserDateSaisie(valeur(ChampCni.expiration));
    if (naissance == null || delivrance == null || expiration == null) {
      return null;
    }
    return DonneesCni(
      nomLegal: valeur(ChampCni.nom).trim(),
      prenomLegal: valeur(ChampCni.prenom).trim(),
      numeroCni: normaliserNumeroCni(valeur(ChampCni.numero)),
      dateNaissance: naissance,
      lieuNaissance: valeur(ChampCni.lieu).trim(),
      dateEtablissement: delivrance,
      dateExpiration: expiration,
    );
  }
}
