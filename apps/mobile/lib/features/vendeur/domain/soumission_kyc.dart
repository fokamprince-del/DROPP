import '../../../core/api/api_exception.dart';
import '../data/modeles_kyc.dart';
import 'etape_kyc.dart';

/// Étapes obligatoires pas encore terminées.
List<EtapeKyc> etapesIncompletes(DossierKyc? dossier) {
  final statuts = statutDesEtapes(dossier);
  return [
    for (final etape in const [
      EtapeKyc.cni,
      EtapeKyc.informations,
      EtapeKyc.selfie,
    ])
      if (statuts[etape] != StatutEtapeKyc.terminee) etape,
  ];
}

/// Contrôle d'interface avant l'appel : le serveur reste l'autorité.
bool pretASoumettre(DossierKyc? dossier) {
  if (dossier == null) return false;
  if (dossier.statut.enVerification ||
      dossier.statut == StatutDossierKyc.valide) {
    return false;
  }
  return etapesIncompletes(dossier).isEmpty;
}

/// Empreinte du contenu du dossier. Une clé d'idempotence ne sert qu'à un
/// même contenu : si le dossier change, c'est une nouvelle action.
String signatureDossier(DossierKyc dossier) {
  final d = dossier.donnees;
  return [
    for (final type in TypeDocumentKyc.values)
      '${type.valeurApi}:${dossier.document(type)?.id ?? '-'}',
    d.nomLegal,
    d.prenomLegal,
    d.numeroCni,
    d.dateNaissance?.toIso8601String(),
    d.lieuNaissance,
    d.dateEtablissement?.toIso8601String(),
    d.dateExpiration?.toIso8601String(),
  ].join('|');
}

/// `•••••456` : garde les trois derniers caractères.
String masquerNumeroCni(String numero) {
  if (numero.length <= 3) return numero;
  return '${'•' * (numero.length - 3)}${numero.substring(numero.length - 3)}';
}

/// L'issue est inconnue : le serveur a peut-être enregistré la soumission.
bool issueIncertaine(TypeErreurApi type) => switch (type) {
  TypeErreurApi.reseau ||
  TypeErreurApi.delaiDepasse ||
  TypeErreurApi.serveur ||
  TypeErreurApi.inconnu ||
  TypeErreurApi.conflit => true,
  _ => false,
};

/// Étape ouverte depuis le récapitulatif : elle y revient au lieu d'enchaîner.
String cheminDepuisRecapitulatif(String chemin) =>
    Uri(path: chemin, queryParameters: {'depuis': 'recap'}).toString();
